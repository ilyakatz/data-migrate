class SilversheetMigration < ActiveRecord::Migration
  def create_progress_bar(title:, count:)
    ProgressBar.create(
      title: title,
      total: count,
      format: "%a %c/%C <%B> %p%% %t %e"
    )
  end

  def setup(title: title_from_class_name, count:)
    @primary_progress_bar = create_progress_bar(title: title, count: count)
  end

  def increment!(progress_bar = @primary_progress_bar)
    progress_bar.increment
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def title_from_class_name
    self.class.to_s.underscore.humanize
  end
end
