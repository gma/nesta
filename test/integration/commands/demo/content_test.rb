require 'test_helper'
require_relative '../../../support/silence_commands_during_tests'
require_relative '../../../../lib/nesta/commands'

Nesta::Commands::Demo::Content.send(:include, SilenceCommandsDuringTests)

describe 'nesta demo:content' do
  include TemporaryFiles

  before do
    Nesta::Commands::Demo::Content.demo_repository = '../../fixtures/demo-content.git'
  end

  it 'clones the demo repository and configures project to use it' do
    in_temporary_project do
      Nesta::Commands::Demo::Content.new.execute
      assert_exists_in_project 'content-demo/pages/index.haml'

      yaml = File.read(File.join(project_root, 'config', 'config.yml'))
      assert_match /content: content-demo/, yaml
    end
  end

  it 'ensures demo repository is ignored by git' do
    in_temporary_project do
      FileUtils.mkdir('.git')
      Nesta::Commands::Demo::Content.new.execute
      assert_match /content-demo/, File.read(project_path('.git/info/exclude'))
    end
  end
end
