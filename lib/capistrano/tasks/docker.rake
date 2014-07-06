namespace :docker do
    

    desc "Prepares the container to store structured docker apps"
    task :prepare do
        on roles :host do
            execute "mkdir -p #{fetch(:docker_buildpath)}"
            execute "mkdir -p #{fetch(:docker_mountpath)}"
        end
    end
    
    desc "build an updated box, restart container"
    task :build do
        on roles :host do
            execute "docker build --no-cache=true -t #{fetch(:docker_appname)}_img #{fetch(:docker_buildpath)}/"
            execute "docker kill #{fetch(:docker_appname)}" rescue ""
            execute "docker rm #{fetch(:docker_appname)}" rescue ""
            execute build_run_command
        end
    end

    def build_run_command()
        cmd = "docker run "
        fetch(:ports).each do |port,map|
           cmd << "-p #{port}:#{map} "
        end
        fetch(:volumes).each do |name,vol|
            execute "mkdir -p -m7777 #{fetch(:docker_mountpath)}/#{name}"
            cmd << "-v `pwd`/#{fetch(:docker_mountpath)}/#{name}:#{vol}:rw "
        end
        cmd << "-name #{fetch(:docker_appname)} "
        cmd << "-e APP_USER='#{fetch(:docker_appname)}' "
        cmd << "-e APP_PASS='#{fetch(:password)}' "
        cmd << "-e APP_DB='#{fetch(:docker_appname)}' "
        cmd << "-d -t #{fetch(:docker_appname)}_img:latest "
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