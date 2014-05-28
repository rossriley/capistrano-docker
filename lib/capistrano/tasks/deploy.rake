namespace :deploy do

    
    desc "Checks that the required configuration parameters are set"
    task :check do 
        on roles :all do
            if roles(:host).length==0
                error "You do not have any host machines defined in your capfile. Try eg: server 'host.example.com', user:youruser, roles: %w{host}"
                exit 
            end
            if !fetch(:port)
                error "You do not have a port variable defined in your capfile. Try eg: set :port, 11111"
                exit
            end 
            if !fetch(:namespace)
                error "You do not have a docker namespace variable defined in your capfile. Try eg: set :namespace, yourname"
                exit 
            end
            if !File.exists?('Dockerfile')
                error "You need to have a Dockerfile setup in the root of your project"
                exit 
            end
            run_locally do 
                outp = capture "git ls-files Dockerfile"
                if outp.length == 0
                    error "You need to have a Dockerfile commited into the root of your project. Try using: git add Dockerfile and then git commit"
                    exit 
                end
            end

        end
    end
    
    desc "Builds project locally ready for deploy."
    task :build do
        puts "Preparing local build note, only code commited to your local Git repository will be included."
        begin
            sh "ls tmp/build/.git"
        rescue
            sh "mkdir -p tmp/build"
            sh "cd tmp/build && git clone ../../ ."
        end
        sh "cd tmp/build/ && git fetch && git checkout -f origin/HEAD"
        fetch(:build_commands).each do |command|
            sh "cd tmp/build && "+command       
        end
        
        
    end
    
    desc "Updates the code on the remote container"
    task :update do
        on roles :host do |host|
            info "Running Rsync to: #{host.user}@#{host.hostname}"
            run_locally do
                execute "cd tmp/build/ && rsync -avR --exclude '.git' ./* #{host.user}@#{host.hostname}:#{fetch(:docker_buildpath)}/"
            end
        end
    end
    
    task :container do 
        invoke "docker:prepare"
    end
    
    task :deploy do
        invoke "docker:build"
    end
    
    task :finished do 
        
    end
    
end

desc 'Deploy a new release.'
task :deploy do
  set(:deploying, true)
  %w{ check build container update deploy finished }.each do |task|
    invoke "deploy:#{task}"
  end
end
task default: :deploy
invoke 'load:defaults'



