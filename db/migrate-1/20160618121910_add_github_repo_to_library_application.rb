class AddGithubRepoToLibraryApplication < ActiveRecord::Migration
  def change
    add_column :library_applications, :git_repo, :string
  end
end
