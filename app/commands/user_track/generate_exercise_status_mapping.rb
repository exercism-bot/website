class UserTrack
  class GenerateExerciseStatusMapping
    include Mandate

    initialize_with :track, :user_track

    def call
      user_track.concept_slugs.each.with_object({}) do |slug, hash|
        hash[slug] = mapping[slug].to_a
      end
    end

    private
    memoize
    def mapping
      mapping = Hash.new { |k, v| k[v] = Set.new }

      Exercise::TaughtConcept.joins(:exercise, :concept).
        where('exercises.track_id': track.id).
        pluck("track_concepts.slug", "exercises.slug").
        each do |concept_slug, exercise_slug|
        next if concept_slug.nil?
        next if exercise_slug.nil?

        mapping[concept_slug] << exercise_slug
      end

      Exercise::PracticedConcept.joins(:exercise, :concept).
        where('exercises.track_id': track.id).
        pluck("track_concepts.slug", "exercises.slug").
        each do |concept_slug, exercise_slug|
        next if concept_slug.nil?
        next if exercise_slug.nil?

        mapping[concept_slug] << exercise_slug
      end

      mapping.transform_values do |exercise_slugs|
        # We use compact here just in case we don't have a
        # slug for an exercise for some reason (this has happened
        # in local testing).
        exercise_slugs.map do |slug|
          {
            url: Exercism::Routes.track_exercise_path(track.slug, slug),
            status: (user_track.external? ? "available" : user_track.exercise_status(slug)),
            type: user_track.exercise_type(slug)
          }
        end.compact
      end
    end
  end
end
