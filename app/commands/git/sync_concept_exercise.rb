module Git
  class SyncConceptExercise < Sync
    include Mandate

    def initialize(exercise, force_sync: false)
      super(exercise.track, exercise.synced_to_git_sha)
      @exercise = exercise
      @force_sync = force_sync
    end

    def call
      unless force_sync || exercise_needs_updating?
        return exercise.update!(synced_to_git_sha: head_git_exercise.synced_git_sha)
      end

      exercise.update!(
        slug: exercise_config[:slug],
        git_sha: head_git_exercise.synced_git_sha,
        synced_to_git_sha: head_git_exercise.synced_git_sha,
        status: exercise_config[:status] || :active,
        icon_name: head_git_exercise.icon_name,
        position: exercise_position,
        # TODO: Remove the || ... once we have configlet checking things properly.
        title: exercise_config[:name].presence || exercise_config[:slug].titleize,
        blurb: head_git_exercise.blurb,
        taught_concepts: find_concepts(exercise_config[:concepts]),
        prerequisites: find_concepts(exercise_config[:prerequisites])
      )

      SyncAuthors.(exercise)
      SyncContributors.(exercise)
    end

    private
    attr_reader :exercise, :force_sync

    def exercise_needs_updating?
      track_config_exercise_modified? || exercise_config_modified? || exercise_files_modified?
    end

    def track_config_exercise_modified?
      return false unless track_config_modified?

      exercise_position != exercise.position ||
        exercise_config[:slug] != exercise.slug ||
        exercise_config[:name] != exercise.title ||
        (exercise_config[:status] || :active) != exercise.status ||
        exercise_config[:concepts].to_a.sort != exercise.taught_concepts.map(&:slug).sort ||
        exercise_config[:prerequisites].to_a.sort != exercise.prerequisites.map(&:slug).sort
    end

    def exercise_config_modified?
      return false unless filepath_in_diff?(head_git_exercise.config_absolute_filepath)

      head_git_exercise.blurb != exercise.blurb ||
        head_git_exercise.icon_name != exercise.icon_name
    end

    def exercise_files_modified?
      head_git_exercise.tooling_absolute_filepaths.any? { |filepath| filepath_in_diff?(filepath) }
    end

    def find_concepts(slugs)
      slugs.to_a.map do |slug|
        concept_config = head_git_track.concepts.find { |e| e[:slug] == slug }
        ::Track::Concept.find_by!(uuid: concept_config[:uuid])
      rescue StandardError
        # TODO: Remove this rescue when configlet works
      end.compact
    end

    memoize
    def exercise_position
      # Offset by 1 to account for the hello-world exercise
      # always being the very first exercise
      exercise_index + 1
    end

    memoize
    def exercise_index
      head_git_track.concept_exercises.find_index { |e| e[:uuid] == exercise.uuid }
    end

    memoize
    def exercise_config
      head_git_track.concept_exercises[exercise_index]
    end

    memoize
    def head_git_exercise
      Git::Exercise.new(exercise_config[:slug], exercise.git_type, git_repo.head_sha, repo: git_repo)
    end
  end
end
