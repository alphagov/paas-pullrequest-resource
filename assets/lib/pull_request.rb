require 'octokit'

class PullRequest
  def initialize(repo:, pr:)
    @repo = repo
    @pr = pr
  end

  def ready?
    statuses.empty?
  end

  def from_fork?
    base_repo != head_repo
  end

  def equals?(id:, sha:)
    [self.sha, self.id.to_s] == [sha, id.to_s]
  end

  def to_json(*)
    as_json.to_json
  end

  def as_json
    { 'ref' => sha, 'pr' => id.to_s }
  end

  def id
    @pr['number']
  end

  def sha
    @pr['head']['sha']
  end

  def url
    @pr['html_url']
  end

  private

  def base_repo
    @pr['base']['repo']['full_name']
  end

  def head_repo
    @pr['head']['repo']['full_name']
  end

  def statuses
    @statuses ||= Octokit.statuses(@repo.name, sha).select do |status|
      status['context'] =~ /^concourse-ci/
    end
  end
end
