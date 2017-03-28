module Layer
  module Resources
    class Notification < Layer::Resource
      def create(recipients, content)
        client.post(create_url, content.merge(recipients: recipients))
      end

      private

      def create_url
        "notifications"
      end
    end
  end
end
