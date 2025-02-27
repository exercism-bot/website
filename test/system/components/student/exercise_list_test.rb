require "application_system_test_case"
require_relative "../../../support/capybara_helpers"
require_relative "../../../support/websockets_helpers"
require_relative "../../../support/markdown_editor_helpers"

module Components
  module Student
    class ExerciseListTest < ApplicationSystemTestCase
      include CapybaraHelpers
      include WebsocketsHelpers
      include MarkdownEditorHelpers

      test "shows exercises" do
        user = create :user
        track = create :track
        create :concept_exercise, track: track, title: "Lasagna"
        create :user_track, track: track, user: user

        use_capybara_host do
          sign_in!(user)
          visit track_exercises_path(track)
        end

        assert_text "Lasagna"
      end

      test "searches exercises" do
        user = create :user
        track = create :track
        create :concept_exercise, track: track, title: "Lasagna", slug: "lasagna"
        create :concept_exercise, track: track, title: "Running", slug: "running"
        create :user_track, track: track, user: user

        use_capybara_host do
          sign_in!(user)
          visit track_exercises_path(track)
          fill_in "Search by title", with: "Running"
        end

        assert_text "Running"
        assert_no_text "Lasagna"
      end

      test "filters exercises by status" do
        user = create :user
        track = create :track
        lasagna = create :concept_exercise, track: track, title: "Lasagna", slug: "lasagna"
        create :concept_exercise, track: track, title: "Running", slug: "running"
        create :user_track, track: track, user: user
        solution = create :concept_solution, exercise: lasagna, user: user
        submission = create :submission, solution: solution
        create :iteration, solution: solution, submission: submission

        use_capybara_host do
          sign_in!(user)
          visit track_exercises_path(track)
          click_on "In Progress"
        end

        assert_text "Lasagna"
        assert_no_text "Running"
      end
    end
  end
end
