require File.expand_path("spec_helper", File.dirname(__FILE__))
require File.expand_path("../lib/nesta/commands", File.dirname(__FILE__))

describe "nesta" do
  before(:each) do
    create_temp_directory
    @project_path = temp_path('mysite.com')
  end
  
  after(:each) do
    remove_temp_directory
  end
  
  def project_path(path)
    File.join(@project_path, path)
  end

  def should_exist(file)
    File.exist?(project_path(file)).should be_true
  end

  def create_config_yaml(text)
    File.open(Nesta::Config.yaml_path, 'w') { |f| f.puts(text) }
  end

  describe "new" do
    def gemfile_source
      File.read(project_path('Gemfile'))
    end

    def rakefile_source
      File.read(project_path('Rakefile'))
    end

    describe "without options" do
      before(:each) do
        Nesta::Commands::New.new(@project_path).execute
      end

      it "should create the content directories" do
        should_exist('content/attachments')
        should_exist('content/pages')
      end

      it "should create the home page" do
        should_exist('content/pages/index.haml')
      end

      it "should create the rackup file" do
        should_exist('config.ru')
      end

      it "should create the config.yml file" do
        should_exist('config/config.yml')
      end

      it "should add a Gemfile" do
        should_exist('Gemfile')
        gemfile_source.should match(/gem 'nesta', '#{Nesta::VERSION}'/)
      end
    end

    describe "--git" do
      before(:each) do
        @command = Nesta::Commands::New.new(@project_path, 'git' => '')
        @command.stub(:system)
      end

      it "should create a .gitignore file" do
        @command.execute
        File.read(project_path('.gitignore')).should match(/\.bundle/)
      end

      it "should create a git repo" do
        @command.should_receive(:system).with('git', 'init')
        @command.execute
      end

      it "should commit the blank project" do
        @command.should_receive(:system).with('git', 'add', '.')
        @command.should_receive(:system).with(
            'git', 'commit', '-m', 'Initial commit')
        @command.execute
      end
    end

    describe "--vlad" do
      before(:each) do
        Nesta::Commands::New.new(@project_path, 'vlad' => '').execute
      end

      it "should add vlad to Gemfile" do
        gemfile_source.should match(/gem 'vlad', '2.1.0'/)
        gemfile_source.should match(/gem 'vlad-git', '2.2.0'/)
      end

      it "should configure the vlad rake tasks" do
        should_exist('Rakefile')
        rakefile_source.should match(/require 'vlad'/)
      end

      it "should create deploy.rb" do
        should_exist('config/deploy.rb')
        deploy_source = File.read(project_path('config/deploy.rb'))
        deploy_source.should match(/set :application, 'mysite.com'/)
      end
    end
  end

  describe "demo:content" do
    before(:each) do
      @config_path = project_path('config/config.yml')
      FileUtils.mkdir_p(File.dirname(@config_path))
      Nesta::Config.stub(:yaml_path).and_return(@config_path)
      create_config_yaml('content: path/to/content')
      Nesta::App.stub(:root).and_return(@project_path)
      @repo_url = 'git://github.com/gma/nesta-demo-content.git'
      @demo_path = project_path('content-demo')
      @command = Nesta::Commands::Demo::Content.new
      @command.stub(:system)
    end

    it "should clone the repository" do
      @command.should_receive(:system).with(
          'git', 'clone', @repo_url, @demo_path)
      @command.execute
    end

    it "should configure the content directory" do
      @command.execute
      File.read(@config_path).should match(/^content: content-demo/)
    end

    describe "when repository already exists" do
      before(:each) do
        FileUtils.mkdir_p(@demo_path)
      end

      it "should update the repository" do
        @command.should_receive(:system).with('git', 'pull', 'origin', 'master')
        @command.execute
      end
    end

    describe "when site versioned with git" do
      before(:each) do
        @exclude_path = project_path('.git/info/exclude')
        FileUtils.mkdir_p(File.dirname(@exclude_path))
        File.open(@exclude_path, 'w') { |file| file.puts '# Excludes' }
      end

      it "should tell git to ignore content-demo" do
        @command.execute
        File.read(@exclude_path).should match(/content-demo/)
      end

      describe "and content-demo already ignored" do
        before(:each) do
          File.open(@exclude_path, 'w') { |file| file.puts 'content-demo' }
        end

        it "shouldn't tell git to ignore it twice" do
          @command.execute
          File.read(@exclude_path).scan('content-demo').size.should == 1
        end
      end
    end
  end

  describe "edit" do
    before(:each) do
      Nesta::Config.stub(:content_path).and_return('content')
      @page_path = 'path/to/page.mdown'
      @command = Nesta::Commands::Edit.new(@page_path)
      @command.stub(:system)
    end

    it "should launch the editor" do
      ENV['EDITOR'] = 'vi'
      full_path = File.join('content/pages', @page_path)
      @command.should_receive(:system).with(ENV['EDITOR'], full_path)
      @command.execute
    end

    it "should not try and launch an editor if environment not setup" do
      ENV.delete('EDITOR')
      @command.should_not_receive(:system)
      $stderr.stub(:puts)
      @command.execute
    end
  end

  describe "plugin:create" do
    before(:each) do
      @name = 'my-feature'
      @gem_name = "nesta-plugin-#{@name}"
      @plugins_path = temp_path('plugins')
      @working_dir = Dir.pwd
      Dir.mkdir(@plugins_path)
      Dir.chdir(@plugins_path)
      @command = Nesta::Commands::Plugin::Create.new(@name)
      @command.stub(:system)
    end

    after(:each) do
      Dir.chdir(@working_dir)
      FileUtils.rm_r(@plugins_path)
    end

    it "should create a new gem prefixed with nesta-plugin" do
      @command.should_receive(:system).with('bundle', 'gem', @gem_name)
      begin
        @command.execute
      rescue Errno::ENOENT
        # This test is only concerned with running bundle gem; ENOENT
        # errors are raised because we didn't create a real gem.
      end
    end

    describe "after gem created" do
      def create_gem_file(*components)
        path = File.join(@plugins_path, @gem_name, *components)
        FileUtils.makedirs(File.dirname(path))
        File.open(path, 'w') { |f| yield f if block_given? }
        path
      end

      before(:each) do
        @required_file = create_gem_file('lib', "#{@gem_name}.rb")
        @init_file = create_gem_file('lib', @gem_name, 'init.rb')
        @gem_spec = create_gem_file("#{@gem_name}.gemspec") do |file|
          file.puts "  # specify any dependencies here; for example:"
          file.puts "end"
        end
      end

      after(:each) do
        FileUtils.rm(@required_file)
        FileUtils.rm(@init_file)
      end

      it "should create the ruby file loaded on require" do
        @command.execute
        File.read(@required_file).should include('Plugin.register(__FILE__)')
      end

      it "should create a default init.rb file" do
        @command.execute
        init = File.read(@init_file)
        boilerplate = <<-EOF
    module My::Feature
      module Helpers
        EOF
        init.should include(boilerplate)
        init.should include('helpers Nesta::Plugin::My::Feature::Helpers')
      end

      it "should specify plugin gem's dependencies" do
        @command.execute
        text = File.read(@gem_spec)
        text.should include('gem.add_dependency("nesta", ">= 0.9.11")')
        text.should include('gem.add_development_dependency("rake")')
      end
    end
  end

  describe "theme:install" do
    before(:each) do
      @repo_url = 'git://github.com/gma/nesta-theme-mine.git'
      @theme_dir = 'themes/mine'
      FileUtils.mkdir_p(File.join(@theme_dir, '.git'))
      @command = Nesta::Commands::Theme::Install.new(@repo_url)
      @command.stub(:enable)
      @command.stub(:system)
    end

    after(:each) do
      FileUtils.rm_r(@theme_dir)
    end

    it "should clone the repository" do
      @command.should_receive(:system).with(
          'git', 'clone', @repo_url, @theme_dir)
      @command.execute
    end

    it "should remove the theme's .git directory" do
      @command.execute
      File.exist?(@theme_dir).should be_true
      File.exist?(File.join(@theme_dir, '.git')).should be_false
    end

    it "should enable the freshly installed theme" do
      @command.should_receive(:enable)
      @command.execute
    end

    describe "when theme URL doesn't match recommended pattern" do
      before(:each) do
        @repo_url = 'git://foobar.com/path/to/mytheme.git'
        @other_theme_dir = 'themes/mytheme'
        FileUtils.mkdir_p(File.join(@other_theme_dir, '.git'))
        @command = Nesta::Commands::Theme::Install.new(@repo_url)
        @command.stub(:enable)
      end

      after(:each) do
        FileUtils.rm_r(@other_theme_dir)
      end

      it "should use the basename as theme dir" do
        @command.should_receive(:system).with(
            'git', 'clone', @repo_url, @other_theme_dir)
        @command.execute
      end
    end
  end

  describe "theme:enable" do
    before(:each) do
      config = temp_path('config.yml')
      Nesta::Config.stub(:yaml_path).and_return(config)
      @name = 'mytheme'
      @command = Nesta::Commands::Theme::Enable.new(@name)
    end

    shared_examples_for "command that configures the theme" do
      it "should enable the theme" do
        @command.execute
        File.read(Nesta::Config.yaml_path).should match(/^theme: #{@name}/)
      end
    end

    describe "when theme config is commented out" do
      before(:each) do
        create_config_yaml('  # theme: blah')
      end

      it_should_behave_like "command that configures the theme"
    end

    describe "when another theme is configured" do
      before(:each) do
        create_config_yaml('theme: another')
      end

      it_should_behave_like "command that configures the theme"
    end

    describe "when no theme config exists" do
      before(:each) do
        create_config_yaml('# I have no theme config')
      end

      it_should_behave_like "command that configures the theme"
    end
  end

  describe "theme:create" do
    def should_exist(file)
      File.exist?(Nesta::Path.themes(@name, file)).should be_true
    end

    before(:each) do
      Nesta::App.stub(:root).and_return(TempFileHelper::TEMP_DIR)
      @name = 'my-new-theme'
      Nesta::Commands::Theme::Create.new(@name).execute
    end

    it "should create the theme directory" do
      File.directory?(Nesta::Path.themes(@name)).should be_true
    end

    it "should create a dummy README file" do
      should_exist('README.md')
      text = File.read(Nesta::Path.themes(@name, 'README.md'))
      text.should match(/#{@name} is a theme/)
    end

    it "should create a default app.rb file" do
      should_exist('app.rb')
    end

    it "should create public and views directories" do
      should_exist("public/#{@name}")
      should_exist('views')
    end

    it "should copy the default view templates into views" do
      %w(layout.haml page.haml master.sass).each do |file|
        should_exist("views/#{file}")
      end
    end
  end
end
