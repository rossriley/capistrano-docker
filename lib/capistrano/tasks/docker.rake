namespace :docker do
    

    desc "Prepares the container to store structured docker apps"
    task :prepare do
        on roles :all do
            execute "mkdir -p `pwd`/#{fetch(:docker_buildpath)}"
            execute "mkdir -p `pwd`/#{fetch(:docker_mountpath)}"
            execute "cd #{fetch(:docker_buildpath)} && rm -Rf ./*" rescue ""
        end
    end
    
    desc "build an updated box, restart container"
    task :build do
        run "docker build -t #{fetch(:account)}/#{fetch(:application)} containers/#{fetch(:application)}/"
        run "docker kill #{fetch(:application)}" rescue ""
        run "docker rm #{fetch(:application)}" rescue ""
        run build_run_command
    end

    def build_run_command()
        cmd = "docker run -p #{fetch(:port)}:80 "
        volumes.each do |vol|
            run "mkdir -p -m7777 /home/docker/mounts/#{fetch(:application)}/#{vol}"
            cmd << "-v /home/docker/mounts/#{fetch(:application)}/#{vol}:/var/www/#{vol}:rw "
        end
        cmd << "-name #{fetch(:application)} "
        cmd << "-d -t #{fetch(:account)}/#{fetch(:application)}:latest"
        cmd
    end
end

namespace :load do

    task :defaults do
        
        set  :docker_workpath,         "dockerappliance/containers/#{fetch(:account)}/#{fetch(:application)}"
        set  :docker_buildpath,        "#{fetch(:docker_workpath)}/config"
        set  :docker_mountpath,        "#{fetch(:docker_workpath)}/mounts"
        set  :docker_appname,          "#{fetch(:account)}_#{fetch(:application)}"
        
        
    end

end