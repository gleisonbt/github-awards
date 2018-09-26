class RepositoryUpdateWorker
  include Sidekiq::Worker
  sidekiq_options throttle: { threshold: 5000, period: 1.hour }

  def perform(user_id, name)
    Rails.logger.info "Updating repositories for user #{user_id}"
    user = User.find(user_id)
    github_token = user.token || ENV['GITHUB_TOKEN']

    #result = Models::GithubClient.new(github_token).get(:repo, {owner: user.login, repo: name})
    result = Github::Repository.find(:repo, :login)
    repo = user.repositories.where(name: name).first_or_initialize
    if result.nil?
      Rails.logger.error "Repo not found : #{repo}"
      return 
    end
    
    update_repo(repo, result) 
    
    RankWorker.perform_async(user_id)
  end
  
  def update_repo(repo, result)
    repo.name = result.name
    repo.github_id = result.id
    repo.forked = result.is_fork
    repo.stars = result.stargazers.total_count
    repo.language = result.primary_language.name
    repo.save
  end
end