require 'spec_helper'

describe Layer::Resources::Message do
  let(:client) { Layer::Platform::Client.new }

  describe ".create" do
    it "should send a message to a conversation" do
      VCR.use_cassette("conversation_message") do
        conversation = client.conversations.create(conversation_params)
        message = conversation.messages.create(message_params)

        expect(message.id).to_not be_nil
        expect(message.url).to_not be_nil
        expect(message.sent_at).to_not be_nil
      end
    end

    it "should instantiate a Message" do
      VCR.use_cassette("conversation_message") do
        conversation = client.conversations.create(conversation_params)
        message = conversation.messages.create(message_params)

        expect(message).to be_instance_of(described_class)
      end
    end

    context "with invalid params" do
      it "should raise Layer::Error" do
        VCR.use_cassette("conversation") do
          conversation = client.conversations.create(conversation_params)

          VCR.use_cassette("message_error", exclusive: true) do
            expect{
              conversation.messages.create
            }.to raise_error(Layer::Error)
          end
        end
      end
    end
  end

  describe ".list" do
    context "for a conversation" do
      it "should return all messages for that conversation" do
        VCR.use_cassette("conversation_messages") do
          conversation = client.conversations.create(conversation_params)

          VCR.use_cassette("messages", exclusive: true) do
            3.times { conversation.messages.create(message_params) }

            messages = conversation.messages.list
            expect(messages.count).to eq(3)
          end
        end
      end

      it "should return empty collection if non found" do
        VCR.use_cassette("conversation_no_messages") do
          conversation = client.conversations.create(conversation_params.merge({distinct: false}))

          messages = conversation.messages.list
          expect(messages).to eq([])
        end
      end

      it "should return a collection of Message objects" do
        VCR.use_cassette("conversation_messages") do
          conversation = client.conversations.create(conversation_params)

          VCR.use_cassette("messages", exclusive: true) do
            3.times { conversation.messages.create(message_params) }

            messages = conversation.messages.list

            messages.each do |msg|
              expect(msg).to be_instance_of(described_class)
              expect(msg.conversation["id"]).to eq(conversation.id)
            end
          end
        end
      end
    end
  end

  describe ".find" do
    context "in a conversation" do
      it "should return message" do
        VCR.use_cassette("conversation_find") do
          conv = client.conversations.create(conversation_params)

          VCR.use_cassette("messages", exclusive: true) do
            existing_msg = conv.messages.create(message_params)
            msg = conv.messages.find(existing_msg.uuid)

            expect(msg).to_not be_nil
            expect(msg).to be_instance_of(described_class)
            expect(msg.conversation["id"]).to eq(conv.id)
          end
        end
      end
    end
  end

  describe "#destroy" do
    it "should delete message if message exists" do
      VCR.use_cassette("message_delete") do
        conv = client.conversations.create(conversation_params)
        message = conv.messages.create(message_params)

        message.destroy

        expect {
          conv.messages.find(message.uuid)
        }.to raise_error(Layer::Errors::NotFound)
      end
    end
  end

  describe "#delete_url" do
    it "should return correct URL needed for deletion" do
      attributes = {
        "id"=>"layer:///messages/779fe2ec-8c1a-4b7c-993c-22df0465af1c",
        "conversation" => {
          "id" => "layer:///conversations/b127ccbe-5f95-4d6a-9c01-c1e98e147f4f"
        }
      }

      message = described_class.new(attributes, nil)
      delete_url = message.send(:delete_url)
      expected_url = "conversations/b127ccbe-5f95-4d6a-9c01-c1e98e147f4f/messages/779fe2ec-8c1a-4b7c-993c-22df0465af1c"

      expect(delete_url).to eq(expected_url)
    end
  end
end
