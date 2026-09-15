# frozen_string_literal: true

require "minitest/autorun"
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
end

