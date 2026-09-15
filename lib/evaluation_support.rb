# frozen_string_literal: true

require "csv"
require "digest"
require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "time"
require "yaml"

module PerfgateEvaluation
  ROOT = File.expand_path("..", __dir__)
  OUTCOMES = %w[pass warn fail inconclusive incomparable].freeze
  IDENTIFIER = /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/

  module_function

  def read_yaml(path)
    YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
  end

  def read_json(path)
    JSON.parse(File.read(path))
  end

  def sha256_file(path)
    "sha256:#{Digest::SHA256.file(path).hexdigest}"
  end

  def sha256_string(value)
    "sha256:#{Digest::SHA256.hexdigest(value)}"
  end

  def canonical_json(value)
    JSON.generate(deep_sort(value))
  end

  def deep_sort(value)
    case value
    when Hash
      value.keys.sort.to_h { |key| [key, deep_sort(value.fetch(key))] }
    when Array
      value.map { |item| deep_sort(item) }
    else
      value
    end
  end

  def write_json(path, value)
    FileUtils.mkdir_p(File.dirname(path))
    temporary = "#{path}.tmp-#{Process.pid}"
    File.write(temporary, "#{JSON.pretty_generate(value)}\n")
    File.rename(temporary, path)
  ensure
    FileUtils.rm_f(temporary) if defined?(temporary)
  end

  def capture(*command, chdir: nil, env: {})
    options = {}
    options[:chdir] = chdir if chdir
    output, status = Open3.capture2e(env, *command, **options)
    abort "#{command.join(' ')} failed:\n#{output}" unless status.success?
    output.strip
  end

  def capture_optional(*command, chdir: nil, env: {})
    options = {}
    options[:chdir] = chdir if chdir
    output, status = Open3.capture2e(env, *command, **options)
    status.success? ? output.strip : nil
  rescue Errno::ENOENT
    nil
  end

  def git(repository, *arguments)
    capture("git", *arguments, chdir: repository)
  end

  def resolve_revision(repository, reference)
    git(repository, "rev-parse", "#{reference}^{commit}")
  end

  def ensure_clean_repository!(repository)
    dirty = git(repository, "status", "--porcelain", "--untracked-files=all")
    abort "refusing to freeze or capture from dirty repository #{repository}" unless dirty.empty?
  end

  def validate_identifier!(label, value)
    abort "#{label} is missing" unless value.is_a?(String) && !value.empty?
    abort "#{label} contains unsupported characters: #{value.inspect}" unless value.match?(IDENTIFIER)
  end

  def perfgate_revision(repository)
    lock = File.read(File.join(repository, "Gemfile.lock"))
    revision = lock[/remote: https:\/\/github\.com\/a11ejandro\/perfgate\.git\n\s+revision: ([0-9a-f]{40})/, 1]
    abort "Gemfile.lock does not contain an exact Perfgate revision" unless revision
    revision
  end

  def rbenv_path
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR)
       .map { |directory| File.join(directory, "rbenv") }
       .find { |candidate| File.executable?(candidate) }
  end

  def required_ruby(repository)
    File.read(File.join(repository, ".ruby-version")).strip
  end

  def ruby_command(repository)
    return [RbConfig.ruby] if RUBY_VERSION.start_with?(required_ruby(repository))
    abort "Ruby #{required_ruby(repository)} is required and rbenv is unavailable" unless rbenv_path

    [rbenv_path, "exec", "ruby"]
  end

  def bundle_command(repository)
    return ["bundle"] if RUBY_VERSION.start_with?(required_ruby(repository))
    abort "Ruby #{required_ruby(repository)} is required and rbenv is unavailable" unless rbenv_path

    [rbenv_path, "exec", "bundle"]
  end

  def machinery_digest
    relative_paths = Dir.chdir(ROOT) do
      Dir.glob("{bin,lib,schemas,.github/workflows}/**/*", File::FNM_DOTMATCH)
         .select { |path| File.file?(path) }
         .sort
    end
    digest = Digest::SHA256.new
    relative_paths.each do |path|
      digest << path << "\0" << File.binread(File.join(ROOT, path)) << "\0"
    end
    "sha256:#{digest.hexdigest}"
  end

  def content_digest(root, relative_paths)
    digest = Digest::SHA256.new
    relative_paths.sort.each do |path|
      digest << path << "\0" << File.binread(File.join(root, path)) << "\0"
    end
    "sha256:#{digest.hexdigest}"
  end

  def runtime_source_paths(root)
    Dir.chdir(root) do
      Dir.glob("{lib,schemas}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }.sort
    end
  end

  def runtime_source_digest(root)
    content_digest(root, runtime_source_paths(root))
  end

  def git_runtime_source_digest(repository, revision)
    paths = git(repository, "ls-tree", "-r", "--name-only", revision, "--", "lib", "schemas").lines.map(&:strip)
    abort "no Perfgate runtime sources found at #{revision}" if paths.empty?
    digest = Digest::SHA256.new
    paths.sort.each do |path|
      content, status = Open3.capture2("git", "show", "#{revision}:#{path}", chdir: repository)
      abort "cannot read #{path} at #{revision}" unless status.success?
      digest << path << "\0" << content << "\0"
    end
    "sha256:#{digest.hexdigest}"
  end

  def resolved_perfgate_path(subject_repository)
    capture(
      *bundle_command(subject_repository), "exec", "ruby", "-e",
      'require "bundler/setup"; print Gem.loaded_specs.fetch("perfgate").full_gem_path',
      chdir: subject_repository
    )
  end

  def verify_sidecar!(path)
    sidecar = "#{path}.sha256"
    abort "missing plan checksum #{sidecar}" unless File.file?(sidecar)
    expected = File.read(sidecar).strip
    actual = sha256_file(path)
    abort "plan checksum mismatch for #{path}" unless expected == actual
    actual
  end

  def environment_snapshot(repository)
    ruby_environment = JSON.parse(capture(
      *ruby_command(repository), "-rjson", "-retc", "-e",
      'print JSON.generate({"description" => RUBY_DESCRIPTION, "platform" => RUBY_PLATFORM, "processors" => Etc.nprocessors})',
      chdir: repository
    ))
    database_environment = {
      "PGHOST" => ENV.fetch("DB_HOST", "localhost"),
      "PGPORT" => ENV.fetch("DB_PORT", "5432"),
      "PGUSER" => ENV.fetch("DB_USERNAME", "baseline"),
      "PGPASSWORD" => ENV.fetch("DB_PASSWORD", "baseline"),
      "PGDATABASE" => ENV.fetch("DB_NAME", "baseline_micropost_test")
    }
    {
      "captured_at" => Time.now.utc.iso8601,
      "declared_class" => nil,
      "ruby" => ruby_environment.fetch("description"),
      "platform" => ruby_environment.fetch("platform"),
      "kernel" => capture("uname", "-a"),
      "processor_count" => ruby_environment.fetch("processors"),
      "processor_model" => capture_optional("sysctl", "-n", "machdep.cpu.brand_string"),
      "ci" => ENV.fetch("CI", "false"),
      "runner_name" => ENV["RUNNER_NAME"],
      "runner_os" => ENV["RUNNER_OS"],
      "runner_arch" => ENV["RUNNER_ARCH"],
      "runner_image" => ENV["ImageOS"] || ENV["PERFGATE_RUNNER_IMAGE"],
      "worker_instance" => ENV["PERFGATE_WORKER_INSTANCE"] || ENV["RUNNER_NAME"] || "unidentified",
      "github_run_id" => ENV["GITHUB_RUN_ID"],
      "github_run_attempt" => ENV["GITHUB_RUN_ATTEMPT"],
      "database_host" => ENV.fetch("DB_HOST", "localhost"),
      "database_port" => ENV.fetch("DB_PORT", "5432"),
      "database_server_version" => capture_optional("psql", "-Atc", "SHOW server_version", env: database_environment)
    }
  end

  def policy_result(summary_path)
    return nil unless File.file?(summary_path)
    File.read(summary_path)[/\*\*Overall policy:\*\*\s+([A-Z_]+)/, 1]&.downcase
  end

  def wilson_interval(successes, total, confidence_level = 0.95)
    return [nil, nil] if total.zero?
    # The study protocol fixes 95%; fail rather than silently using the wrong z.
    abort "only 95% Wilson intervals are implemented" unless (confidence_level - 0.95).abs < 1e-12
    z = 1.959963984540054
    proportion = successes.to_f / total
    denominator = 1.0 + ((z * z) / total)
    center = (proportion + ((z * z) / (2.0 * total))) / denominator
    half = z * Math.sqrt((proportion * (1.0 - proportion) / total) +
                         ((z * z) / (4.0 * total * total))) / denominator
    [[center - half, 0.0].max, [center + half, 1.0].min]
  end

  def median(values)
    return nil if values.empty?
    sorted = values.sort
    midpoint = sorted.length / 2
    sorted.length.odd? ? sorted[midpoint] : (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
  end

  def resolve_downloaded_artifact_path(recorded_path, arm_root:, category:)
    return nil if recorded_path.to_s.empty?
    return recorded_path if File.file?(recorded_path)

    downloaded_path = File.join(arm_root, category, File.basename(recorded_path))
    File.file?(downloaded_path) ? downloaded_path : nil
  end

  def trial_manifest_mismatches(plan:, plan_digest:, trial:, arm:, manifest:)
    expected = {
      "study_id" => plan.fetch("study_id"),
      "stage" => plan.fetch("stage"),
      "trial_id" => trial.fetch("trial_id"),
      "condition" => trial.fetch("condition"),
      "schedule_index" => trial.fetch("schedule_index"),
      "arm" => arm,
      "plan_digest" => plan_digest,
      "app_revision" => trial.fetch("#{arm}_revision"),
      "perfgate_revision" => plan.fetch("perfgate_revision"),
      "perfgate_runtime_source_digest" => plan.fetch("perfgate_runtime_source_digest"),
      "configuration_digest" => plan.dig("subject", "configuration_digest"),
      "status" => "completed"
    }
    mismatches = expected.reject { |key, value| manifest[key] == value }.keys
    declared_class = manifest.dig("environment", "declared_class")
    mismatches << "environment.declared_class" unless declared_class == plan.fetch("environment_class")
    mismatches
  end
end

require "etc"
