#!/usr/bin/env ruby

require 'json'
require_relative 'base'
require_relative '../repository'

module Commands
  class Check < Commands::Base
    attr_reader :input

    def output
      if return_all_versions?
        all_pull_requests
      else
        next_pull_request
      end
    end

    private

    def return_all_versions?
      input['source']['every'] == true
    end

    def disallow_forks?
      input['source']['disallow_forks'] == true
    end

    def all_pull_requests
      repo.pull_requests(disallow_forks: disallow_forks?)
    end

    def next_pull_request
      pull_request = repo.next_pull_request(
        id: input['version']['pr'],
        sha: input['version']['ref'],
        base: input['source']['base'],
        disallow_forks: disallow_forks?,
      )

      if pull_request
        [pull_request]
      else
        []
      end
    end

    def repo
      @repo ||= Repository.new(name: input['source']['repo'])
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  input = JSON.parse(ARGF.read)
  input['version'] ||= {}
  command = Commands::Check.new(input: input)
  puts JSON.generate(command.output)
end
