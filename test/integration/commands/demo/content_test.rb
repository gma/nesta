require 'test_helper'
require_relative '../../../../lib/nesta/commands'

describe 'nesta demo:content' do
  include TemporaryFiles

  before do
    Nesta::Commands::Demo::Content.demo_repository = '../../fixtures/demo-content.git'
  end

  def process_stub
    Object.new.tap do |stub|
      def stub.run(*args); end
    end
  end

  it 'clones the demo repository and configures project to use it' do
    in_temporary_project do
      Nesta::Commands::Demo::Content.new.execute(process_stub)

      yaml = File.read(File.join(project_root, 'config', 'config.yml'))
      assert_match /content: content-demo/, yaml
    end
  end

  it 'ensures demo repository is ignored by git' do
    in_temporary_project do
      FileUtils.mkdir('.git')
      Nesta::Commands::Demo::Content.new.execute(process_stub)
      assert_match /content-demo/, File.read(project_path('.git/info/exclude'))
    end
  end
end
