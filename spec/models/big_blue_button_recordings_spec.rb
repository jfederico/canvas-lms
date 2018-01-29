#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require_relative('web_conference_spec_helper')

describe BigBlueButtonConference do
  include WebMock::API
  include_examples 'WebConference'

  describe 'plugin setting recording_enabled is enabled' do
    before do
      allow(WebConference).to receive(:plugins).and_return([
        web_conference_plugin_mock("big_blue_button", {
          :domain => "bbb.instructure.com",
          :secret_dec => "secret",
          :recording_enabled => true,
        })
      ])
    end

    it "should properly serialize a response with no recordings" do
      bbb = BigBlueButtonConference.new
      allow(bbb).to receive(:conference_key).and_return('12345')
      bbb.user_settings = { record: true }
      bbb.user = user_factory
      bbb.context = course_factory
      bbb.save!
      response = {returncode: 'SUCCESS', recordings: "\n  ",
                  messageKey: 'noRecordings', message: 'There are no recordings for the meeting(s).'}
      allow(bbb).to receive(:send_request).and_return(response)
      recordings = bbb.recordings
      expect(recordings).to eq []
    end

    it "should properly serialize a response with recordings" do
      bbb = BigBlueButtonConference.new
      allow(bbb).to receive(:conference_key).and_return('12345')
      bbb.user_settings = { record: true }
      bbb.user = user_factory
      bbb.context = course_factory
      bbb.save!
      response = {:returncode=>"SUCCESS",
                  :recordings=>[
                    {:recordID=>"18974fe54920ac60ba913e34f49e4a9dabfeea2c-1513031612456",
                     :meetingID=>"instructure_web_conference_oKdQ1gfiZjl0bOy8PQSytaF1vBuwOU3CxHDd4kJr",
                     :name=>"Conference Development 101",
                     :published=>"true",
                     :protected=>"false",
                     :startTime=>"1513031612000",
                     :endTime=>"1513031628000",
                     :metadata=>{:isBreakout=>"false"},
                     :playback=>{
                       :format=>{
                         :type=>"video",
                         :url=>"https://bbb.instructure.com/instructure/18974fe54920ac60ba913e34f49e4a9dabfeea2c-1513031612456/capture/",
                         :length=>"0"
                       }
                     }
                    },
                    {:recordID=>"18974fe54920ac60ba913e34f49e4a9dabfeea2c-1513031142256",
                     :meetingID=>"instructure_web_conference_oKdQ1gfiZjl0bOy8PQSytaF1vBuwOU3CxHDd4kJr",
                     :name=>"Conference Development 101",
                     :published=>"true",
                     :protected=>"false",
                     :startTime=>"1513031142000",
                     :endTime=>"1513031164000",
                     :metadata=>{:isBreakout=>"false"},
                     :playback=>{
                       :format=>{
                         :type=>"video",
                         :url=>"https://bbb.instructure.com/instructure/18974fe54920ac60ba913e34f49e4a9dabfeea2c-1513031142256/capture/",
                         :length=>"0"
                       }
                     }
                    }
                  ]
                 }
      allow(bbb).to receive(:send_request).and_return(response)
      recordings = bbb.recordings
      expect(recordings).not_to eq []
    end

    describe "looking for recordings based on user setting" do
      let(:tool_proxy_fixture){File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))}

      before(:once) do
        @bbb = BigBlueButtonConference.new(user: user_factory, context: course_factory)

        # set some vars so it thinks it's been created and doesn't do an api call
        @bbb.conference_key = 'test'
        @bbb.settings[:admin_key] = 'admin'
        @bbb.settings[:user_key] = 'user'
        @bbb.save
      end

      it "doesn't look if setting is false" do
        @bbb.save
        expect(@bbb).to receive(:send_request).never
        @bbb.recordings
      end

      it "does look if setting is true" do
        @bbb.user_settings = { :record => true }
        @bbb.save
        expect(@bbb).to receive(:send_request)
        @bbb.recordings
      end
    end

    describe "delete recording" do
      let(:tool_proxy_fixture){File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))}

      before(:once) do
        @bbb = BigBlueButtonConference.new(user: user_factory, context: course_factory)
        # set some vars so it thinks it's been created and doesn't do an api call
        @bbb.conference_key = 'test'
        @bbb.settings[:admin_key] = 'admin'
        @bbb.settings[:user_key] = 'user'
        @bbb.save
      end

      it "doesn't delete anything if record_id = nil" do
        recording_id = nil
        allow(@bbb).to receive(:send_request)
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to eq "false"
      end

      it "doesn't delete the recording if record_id is not found" do
        recording_id = ''
        allow(@bbb).to receive(:send_request).and_return({:returncode=>"SUCCESS", :deleted=>"false"})
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to eq "false"
      end

      it "does delete the recording if record_id is found" do
        recording_id = 'abc123-xyz'
        allow(@bbb).to receive(:send_request).and_return({:returncode=>"SUCCESS", :deleted=>"true"})
        response = @bbb.delete_recording(recording_id)
        expect(response[:deleted]).to eq "true"
      end

    end

  end
end
