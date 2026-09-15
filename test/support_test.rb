# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/evaluation_support"

class EvaluationSupportTest < Minitest::Test
  def test_wilson_interval_for_zero_of_one
    lower, upper = PerfgateEvaluation.wilson_interval(0, 1)

    assert_in_delta 0.0, lower, 1e-12
    assert_in_delta 0.7934506856, upper, 1e-9
  end

  def test_wilson_interval_for_empty_denominator_is_unestimated
    assert_equal [nil, nil], PerfgateEvaluation.wilson_interval(0, 0)
  end

  def test_median
    assert_equal 2, PerfgateEvaluation.median([3, 1, 2])
    assert_equal 2.5, PerfgateEvaluation.median([4, 1, 3, 2])
    assert_nil PerfgateEvaluation.median([])
  end

  def test_canonical_json_is_independent_of_hash_order
    first = { "b" => 2, "a" => { "d" => 4, "c" => 3 } }
    second = { "a" => { "c" => 3, "d" => 4 }, "b" => 2 }

    assert_equal PerfgateEvaluation.canonical_json(first), PerfgateEvaluation.canonical_json(second)
  end

  def test_resolve_downloaded_artifact_path_uses_local_bundle_copy
    Dir.mktmpdir do |directory|
      comparisons = File.join(directory, "comparisons")
      FileUtils.mkdir_p(comparisons)
      local = File.join(comparisons, "result.json")
      File.write(local, "{}")

      resolved = PerfgateEvaluation.resolve_downloaded_artifact_path(
        "/home/runner/results/comparisons/result.json",
        arm_root: directory,
        category: "comparisons"
      )

      assert_equal local, resolved
    end
  end

  def test_resolve_downloaded_artifact_path_does_not_invent_a_missing_file
    Dir.mktmpdir do |directory|
      resolved = PerfgateEvaluation.resolve_downloaded_artifact_path(
        "/home/runner/results/comparisons/missing.json",
        arm_root: directory,
        category: "comparisons"
      )

      assert_nil resolved
    end
  end

  def test_trial_manifest_mismatches_detects_another_plan
    plan = {
      "study_id" => "study", "stage" => "calibration", "perfgate_revision" => "p",
      "perfgate_runtime_source_digest" => "runtime", "environment_class" => "runner",
      "subject" => { "configuration_digest" => "config" }
    }
    trial = {
      "trial_id" => "trial-001", "condition" => "aa", "schedule_index" => 1,
      "reference_revision" => "app"
    }
    manifest = {
      "study_id" => "study", "stage" => "calibration", "trial_id" => "trial-001",
      "condition" => "aa", "schedule_index" => 1, "arm" => "reference",
      "plan_digest" => "old-plan", "app_revision" => "app", "perfgate_revision" => "p",
      "perfgate_runtime_source_digest" => "runtime", "configuration_digest" => "config",
      "status" => "completed", "environment" => { "declared_class" => "runner" }
    }

    mismatches = PerfgateEvaluation.trial_manifest_mismatches(
      plan: plan, plan_digest: "new-plan", trial: trial, arm: "reference", manifest: manifest
    )

    assert_equal ["plan_digest"], mismatches
  end
end
