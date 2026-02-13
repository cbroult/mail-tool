require "English"
require "tmpdir"

RSpec.describe MailTool::TokenStore do
  let(:store_path) { File.join(Dir.tmpdir, "mail-tool-test-tokens-#{$PROCESS_ID}.yml") }
  let(:store) { described_class.new(store_path) }
  let(:key) { "imap.example.com/user@example.com" }

  after do
    FileUtils.rm_f(store_path)
  end

  describe ".token_key" do
    it "returns server/username format" do
      expect(described_class.token_key("imap.example.com", "user@example.com"))
        .to eq("imap.example.com/user@example.com")
    end
  end

  describe "#save" do
    it "writes tokens to the YAML file" do
      store.save(key, access_token: "abc", refresh_token: "xyz", expires_at: 1_700_000_000)

      data = YAML.safe_load_file(store_path, permitted_classes: [Symbol])
      expect(data[key]["access_token"]).to eq("abc")
      expect(data[key]["refresh_token"]).to eq("xyz")
      expect(data[key]["expires_at"]).to eq(1_700_000_000)
    end

    it "sets file permissions to 0600" do
      store.save(key, access_token: "abc", refresh_token: "xyz", expires_at: 1_700_000_000)

      mode = File.stat(store_path).mode & 0o777
      expect(mode).to eq(0o600)
    end

    it "preserves existing tokens for other keys" do
      store.save("other/key", access_token: "other", refresh_token: "other", expires_at: 1)
      store.save(key, access_token: "abc", refresh_token: "xyz", expires_at: 2)

      data = YAML.safe_load_file(store_path, permitted_classes: [Symbol])
      expect(data["other/key"]["access_token"]).to eq("other")
      expect(data[key]["access_token"]).to eq("abc")
    end
  end

  describe "#load" do
    it "returns token hash for a known key" do
      store.save(key, access_token: "abc", refresh_token: "xyz", expires_at: 1_700_000_000)

      tokens = store.load(key)
      expect(tokens["access_token"]).to eq("abc")
      expect(tokens["refresh_token"]).to eq("xyz")
      expect(tokens["expires_at"]).to eq(1_700_000_000)
    end

    it "returns nil for an unknown key" do
      store.save("other/key", access_token: "x", refresh_token: "y", expires_at: 1)

      expect(store.load(key)).to be_nil
    end

    it "returns nil when store file does not exist" do
      expect(store.load(key)).to be_nil
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      tokens = { "expires_at" => Time.now.to_i - 60 }

      expect(store.expired?(tokens)).to be true
    end

    it "returns true when token expires within 60 seconds" do
      tokens = { "expires_at" => Time.now.to_i + 30 }

      expect(store.expired?(tokens)).to be true
    end

    it "returns false when token is still valid" do
      tokens = { "expires_at" => Time.now.to_i + 3600 }

      expect(store.expired?(tokens)).to be false
    end

    it "returns true when expires_at is missing" do
      tokens = {}

      expect(store.expired?(tokens)).to be true
    end
  end

  describe "tilde expansion" do
    it "expands ~ in store path" do
      tilde_store = described_class.new("~/test-tokens.yml")
      expected = File.expand_path("~/test-tokens.yml")

      expect(tilde_store.path).to eq(expected)
    end
  end
end
