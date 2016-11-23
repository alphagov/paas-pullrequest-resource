require 'octokit'
require_relative 'pull_request'

class Repository
  attr_reader :name

  def initialize(name:)
    @name = name
  end

  def pull_requests(base: nil, disallow_forks: false)
    @pull_requests ||= load_pull_requests(base: base, disallow_forks: disallow_forks)
  end

  def pull_request(id:)
    pr = Octokit.pull_request(name, id)
    PullRequest.new(repo: self, pr: pr)
  end

  def next_pull_request(id: nil, sha: nil, base: nil, disallow_forks: false)
    return if pull_requests(base: base, disallow_forks: disallow_forks).empty?

    if id && sha
      current = pull_requests(disallow_forks: disallow_forks).find { |pr| pr.equals?(id: id, sha: sha) }
      return if current && current.ready?
    end

    pull_requests(disallow_forks: disallow_forks).find do |pr|
      pr != current && pr.ready?
    end
  end

  private

  def load_pull_requests(base: nil, disallow_forks: false)
    pulls = Octokit.pulls(name, pulls_options(base: base)).map do |pr|
      PullRequest.new(repo: self, pr: pr)
    end
    if disallow_forks
      pulls = pulls.select { |pr| !pr.from_fork? }
    end
    pulls
  end

  def pulls_options(base: nil)
    base ? default_opts.merge(base: base) : default_opts
  end

  def default_opts
    { state: 'open', sort: 'updated', direction: 'asc' }
  end
end
