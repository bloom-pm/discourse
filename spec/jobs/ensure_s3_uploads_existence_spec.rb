# frozen_string_literal: true

RSpec.describe Jobs::EnsureS3UploadsExistence do
  context "S3 inventory enabled" do
    before do
      setup_s3
      SiteSetting.enable_s3_inventory = true
    end

    it "works" do
      S3Inventory.any_instance.expects(:backfill_etags_and_list_missing).once
      subject.execute({})
    end

    it "doesn't execute when the site was restored within the last 48 hours" do
      S3Inventory.any_instance.expects(:backfill_etags_and_list_missing).never
      BackupMetadata.update_last_restore_date(47.hours.ago)

      subject.execute({})
    end

    it "executes when the site was restored more than 48 hours ago" do
      S3Inventory.any_instance.expects(:backfill_etags_and_list_missing).once
      BackupMetadata.update_last_restore_date(49.hours.ago)

      subject.execute({})
    end
  end

  context "S3 inventory disabled" do
    before { SiteSetting.enable_s3_inventory = false }

    it "doesn't execute" do
      S3Inventory.any_instance.expects(:backfill_etags_and_list_missing).never
      subject.execute({})
    end
  end
end
