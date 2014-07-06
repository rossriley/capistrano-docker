namespace :deploy do

    
    desc "Checks that the required configuration parameters are set"
    task :check do 
        on roles :all do
            if roles(:host).length==0
                error "You do not have any host machines defined in your capfile. Try eg: server 'host.example.com', user:youruser, roles: %w{host}"
                exit 
            end
            if !fetch(:ports) || fetch(:ports).length ==0
                error "You do not have any port mappings defined in your capfile. Try eg: set :ports, {11111=>80}"
                exit
            end 
            if !fetch(:namespace)
                error "You do not have a docker namespace variable defined in your capfile. Try eg: set :namespace, yourname"
                exit 
            end
            if !fetch(:password)
                error "You do not have an application password defined in your capfile. Try eg: set :password, secret1234"
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
        puts "Preparing local build: note, only code commited to your local Git repository will be included."
       
        run_locally do
            begin
                capture "ls tmp/build/.git"
            rescue
                execute "mkdir -p tmp/build"
                execute "cd tmp/build && git clone ../../ ."
            end
            
            execute "cd tmp/build/ && git fetch && git checkout -f origin/HEAD"

            fetch(:build_commands).each do |command|
                execute "cd tmp/build && "+command       
            end
            
            execute "echo '"+fetch(:start_commands, []).join(';\n') +"' > tmp/build/start.sh"
            execute "chmod +x tmp/build/start.sh"        
        
        end   
        
        
    end
    
    desc "Updates the code on the remote container"
    task :update do
        on roles :host do |host|
            info " Running Rsync to: #{host.user}@#{host.hostname}"
            run_locally do
                execute "rsync -rup --exclude '.git' tmp/build/* #{host.user}@#{host.hostname}:#{fetch(:docker_buildpath)}/"
            end
        end
    end
    
    task :container do 
        invoke "docker:prepare"
    end
    
    task :deploy do
        invoke "docker:build"
    end
    
    task :proxy do
        on roles :host do |host|
            config = ""
            fetch(:proxies).each do |proxy,port|
                config <<  "server {" + "\n"
                config << "  server_name "+proxy+";" + "\n"
                config << "  location / {" + "\n"
                config << "    proxy_pass http://127.0.0.1:"+port+"/;" + "\n"
                config << "    proxy_set_header Host $http_host;" + "\n"
                config << "  }" + "\n"
                config << "}" + "\n"
            end
            basepath = "dockerappliance/conf/nginx/"
            destination = basepath + fetch(:docker_appname)+".conf"
            io   = StringIO.new(config)
            upload! io,   destination
        end
    end
    
    task :supervisor do
        on roles :host do |host|
            config = ""
            config << "[program:"+fetch(:docker_appname)+"]"+"\n"
            config << "command=docker start -a "+fetch(:docker_appname) + "\n"
            config << "autorestart=true"+"\n"
            destination = "dockerappliance/conf/supervisor/" + fetch(:docker_appname)+".conf"
            io   = StringIO.new(config)
            upload! io,   destination
        end
    end
    
    task :restart do
        on roles :host do |host|
            execute "sudo service nginx restart"
        end
    end
    
    
    task :finished do 
        
    end
    
end

desc 'Deploy a new release.'
task :deploy do
  set(:deploying, true)
  %w{ check build container update deploy proxy supervisor restart finished }.each do |task|
    invoke "deploy:#{task}"
  end
end
task default: :deploy
invoke 'load:defaults'



