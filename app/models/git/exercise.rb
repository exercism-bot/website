module Git
  class Exercise
    extend Mandate::Memoize
    extend Mandate::InitializerInjector
    extend Git::HasGitFilepaths

    delegate :head_sha, :lookup_commit, :head_commit, to: :repo

    git_filepaths instructions: ".docs/instructions.md",
                  instructions_append: ".docs/instructions.append.md",
                  introduction: ".docs/introduction.md",
                  introduction_append: ".docs/introduction.append.md",
                  hints: ".docs/hints.md",
                  config: ".meta/config.json"

    def self.for_solution(solution)
      new(
        solution.git_slug,
        solution.git_type,
        solution.git_sha,
        repo_url: solution.track.repo_url
      )
    end

    def initialize(exercise_slug, exercise_type, git_sha = "HEAD", repo_url: nil, repo: nil)
      @repo = repo || Repository.new(repo_url: repo_url)
      @exercise_slug = exercise_slug
      @exercise_type = exercise_type
      @git_sha = git_sha
    end

    def synced_git_sha
      commit.oid
    end

    def valid_submission_filepath?(filepath)
      return false if filepath.match?(%r{[^a-zA-Z0-9_./-]})
      return false if filepath.starts_with?(".meta")
      return false if filepath.starts_with?(".docs")

      # We don't want to let studetns override the test files. However, some languages
      # have solutions and tests in the same file so we need the second guard for that.
      return false if test_filepaths.include?(filepath) && !solution_filepaths.include?(filepath)

      true
    end

    memoize
    def authors
      config[:authors].to_a
    end

    memoize
    def contributors
      config[:contributors].to_a
    end

    memoize
    def source
      config[:source]
    end

    memoize
    def source_url
      config[:source_url]
    end

    memoize
    def blurb
      config[:blurb]
    end

    memoize
    def icon_name
      config[:icon] || exercise_slug.to_s
    end

    memoize
    def solution_filepaths
      config[:files][:solution]
    end

    memoize
    def test_filepaths
      config[:files][:test]
    end

    memoize
    def exemplar_files
      config[:files][:exemplar].index_with do |filepath|
        read_file_blob(filepath)
      end
    rescue StandardError
      {}
    end

    memoize
    def example_files
      config[:files][:example].index_with do |filepath|
        read_file_blob(filepath)
      end
    rescue StandardError
      {}
    end

    def tests
      read_file_blob(test_filepaths.first)
    end

    # Files that should be transported
    # to a user for use in the editor.
    memoize
    def solution_files
      solution_filepaths.index_with do |filepath|
        read_file_blob(filepath)
      end
    rescue StandardError
      {}
    end

    # This includes meta files
    memoize
    def tooling_files
      tooling_filepaths.each.with_object({}) do |filepath, hash|
        hash[filepath] = read_file_blob(filepath)
      end
    end

    # This includes meta files
    memoize
    def tooling_filepaths
      filepaths.select do |filepath| # rubocop:disable Style/InverseMethods
        !filepath.match?(track.ignore_regexp)
      end
    end

    # This includes meta files
    memoize
    def tooling_absolute_filepaths
      tooling_filepaths.map { |filepath| absolute_filepath(filepath) }
    end

    memoize
    def cli_filepaths
      special_filepaths = [SPECIAL_FILEPATHS[:readme], SPECIAL_FILEPATHS[:help]]
      special_filepaths << SPECIAL_FILEPATHS[:hints] if filepaths.include?(hints_filepath)

      filtered_filepaths = filepaths.select do |filepath| # rubocop:disable Style/InverseMethods
        next if filepath.match?(track.ignore_regexp) # TODO: remove this
        next if filepath.start_with?('.docs/')
        next if filepath.start_with?('.meta/') && filepath != config_filepath

        true
      end

      special_filepaths.concat(filtered_filepaths)
    end

    def read_file_blob(filepath)
      mapped = file_entries.map { |f| [f[:full], f[:oid]] }.to_h
      mapped[filepath] ? repo.read_blob(mapped[filepath]) : nil
    end

    def dir
      "exercises/#{exercise_type}/#{exercise_slug}"
    end

    private
    attr_reader :repo, :exercise_slug, :exercise_type, :git_sha

    def absolute_filepath(filepath)
      "#{dir}/#{filepath}"
    end

    def filepaths
      file_entries.map { |defn| defn[:full] }
    end

    memoize
    def file_entries
      tree.walk(:preorder).map do |root, entry|
        next if entry[:type] == :tree

        entry[:full] = "#{root}#{entry[:name]}"
        entry
      end.compact
    end

    memoize
    def tree
      repo.fetch_tree(commit, dir)
    end

    memoize
    def commit
      repo.lookup_commit(git_sha)
    end

    memoize
    def track
      Track.new(repo: repo)
    end

    SPECIAL_FILEPATHS = {
      readme: 'README.md',
      hints: 'HINTS.md',
      help: 'HELP.md'
    }.freeze
  end
end
