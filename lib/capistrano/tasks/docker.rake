namespace :docker do
    

    desc "Prepares the container to store structured docker apps"
    task :prepare do
        on roles :host do
            execute "mkdir -p `pwd`/#{fetch(:docker_buildpath)}"
            execute "mkdir -p `pwd`/#{fetch(:docker_mountpath)}"
            execute "cd #{fetch(:docker_buildpath)} && rm -Rf ./*" rescue ""
        end
    end
    
    desc "build an updated box, restart container"
    task :build do
        on roles :host do
            execute "docker build -t #{fetch(:docker_appname)} #{fetch(:docker_buildpath)}/"
            execute "docker kill #{fetch(:docker_appname)}" rescue ""
            execute "docker rm #{fetch(:docker_appname)}" rescue ""
            execute build_run_command
        end
    end

    def build_run_command()
        cmd = "docker run -p #{fetch(:port)}:#{fetch(:port)} "
        volumes.each do |vol|
            execute "mkdir -p -m7777 #{fetch(:docker_mountpath)}/#{vol}"
            cmd << "-v `pwd`/#{fetch(:docker_mountpath)}/#{vol}:#{vol}:rw "
        end
        cmd << "-name #{fetch(:docker_appname)} "
        cmd << "-d -t #{fetch(:docker_appname)}:latest"
        cmd
    end
end

namespace :load do

    task :defaults do
        
        set  :docker_workpath,  ->   { "dockerappliance/containers/#{fetch(:namespace)}/#{fetch(:application)}" }         
        set  :docker_buildpath, ->   { "#{fetch(:docker_workpath)}/config" }
        set  :docker_mountpath, ->   { "#{fetch(:docker_workpath)}/mounts" }
        set  :docker_appname,   ->   { "#{fetch(:namespace)}_#{fetch(:application)}" }
        
        
    end

end