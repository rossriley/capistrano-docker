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
            execute "docker build -t #{fetch(:docker_image)} #{fetch(:docker_buildpath)}/"
            execute "docker kill #{fetch(:docker_appname)}" rescue ""
            execute "docker rm #{fetch(:docker_appname)}" rescue ""
            execute build_run_command
        end
    end

    def build_run_command()
        cmd = "docker run "
        fetch(:ports).each do |port|
            if port.is_a?(Hash) && port[:private] && port[:public]
                cmd << "-p #{port[:public]}:#{port[:private]} "
            else
                cmd << "-p #{port} "
            end
        end
        fetch(:volumes).each do |name,vol|
            execute "mkdir -p -m7777 #{fetch(:docker_mountpath)}/#{name}"
            cmd << "-v `pwd`/#{fetch(:docker_mountpath)}/#{name}:#{vol}:rw "
        end
        fetch(:links, {}).each do |link,name|
            cmd << "--link "+link+":"+name+" "
        end
        cmd << "--name #{fetch(:docker_appname)} "
        cmd << "-e APP_USER='#{fetch(:app_username)}' "
        cmd << "-e APP_PASS='#{fetch(:app_password)}' "
        cmd << "-e APP_DB='#{fetch(:app_db)}' "
        fetch(:env_vars, {}).each do |var,value|
            cmd << "-e "+var+"='"+value+"' "
        end
        cmd << "-d -t #{fetch(:docker_image)}:latest "
        cmd
    end
end

namespace :load do

    task :defaults do
        
        set  :docker_workpath,  ->   { "dockerappliance/containers/#{fetch(:namespace)}/#{fetch(:application)}" }         
        set  :docker_buildpath, ->   { "#{fetch(:docker_workpath)}/config" }
        set  :docker_mountpath, ->   { "#{fetch(:docker_workpath)}/mounts" }
        set  :docker_appname,   ->   { "#{fetch(:namespace)}_#{fetch(:application)}" }
        set  :docker_image,   ->     { "#{fetch(:namespace)}_#{fetch(:image, fetch(:application))}" }
        set  :app_username,   ->     { "#{fetch(:docker_appname)}" }
        set  :app_password,   ->     { "#{fetch(:password)}" }
        set  :app_db,   ->           { "#{fetch(:app_username)}" }
        
        
    end

end