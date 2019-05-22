# frozen_string_literal: true

require "rails_helper"

module Overrides
  class KeysController < Rails::Keyserver::Api::V1::KeysController
    def index
      @composed = @composed.date_from(params[:date_from]) if params[:date_from]
      @composed = @composed.date_to params[:date_to] if params[:date_to]

      render json: @composed.all
    end
  end
end

RSpec.describe "Keys requests", type: :request do
  let(:json) do
    begin
      JSON.parse response.body
    rescue JSON::ParserError
      ""
    end
  end

  let(:req_params) do
    {
      format: "json",
    }.merge(filter_params)
  end

  let(:filter_params) do
    {}
  end

  let(:key_path_1) { "spec/data/gpg/spec.pub" }
  let(:key_string_1) { File.read key_path_1 }

  context "when using an overridden controller" do
    before do
      Rails.application.routes.draw do
        mount_keyserver at: "ks", controllers: {
          keys: "overrides/keys",
        }
      end
    end

    after do
      Rails.application.reload_routes!
    end

    describe "#index" do
      let(:action) do
        lambda {
          get "/ks/pgp/keys", params: req_params
        }
      end

      describe "with date_from= & date_to=" do
        let(:now)          { Time.now }
        let(:key_gen_date) { now - 10.years }
        let(:timeline)     do
          [
            -800.years,
            -5.years,
            -3.months,
            -2.days,
            -1.hour,
            -1.minute,
            0,
            1.minute,
            1.hour,
            2.days,
            3.months,
            5.years,
            800.years,
          ].map do |diff|
            key_gen_date + diff
          end
        end

        let(:date_from) { Time.now - 3.years }
        let(:date_to)   { date_from + 6.years }

        before do
          timeline.each do |time|
            key = timecopped(time) do
              # FactoryBot.create :rails_keyserver_key_pgp,
              # activation_date: time
              (RK::Key::PGP.import_key_string key_string_1,
                                              activation_date: time).first
            end

            expect(key.activation_date.to_i).to eq time.to_i
          end
          action.call
        end

        context "with only date_from=" do
          let(:filter_params) do
            {
              date_from: date_from,
            }
          end

          it "returns stuff with activation_date from 'date_from'" do
            json.map do |key|
              expect(Time.parse(key["activation_date"])).to be >= date_from
            end
          end
        end

        context "with only date_to=" do
          let(:filter_params) do
            {
              date_to: date_to,
            }
          end

          it "returns stuff with activation_date to 'date_to'" do
            json.map do |key|
              expect(Time.parse(key["activation_date"])).to be <= date_to
            end
          end
        end

        context "with both date_from= & date_to=" do
          let(:filter_params) do
            {
              date_from: date_from,
              date_to:   date_to,
            }
          end

          it "returns stuff with activation_date from 'date_from'" do
            json.map do |key|
              expect(Time.parse(key["activation_date"])).to be >= date_from
            end
          end

          it "returns stuff with activation_date to 'date_to'" do
            json.map do |key|
              expect(Time.parse(key["activation_date"])).to be <= date_to
            end
          end

          context "but date_to= is less than date_from=" do
            let(:filter_params) do
              {
                date_from: date_to,
                date_to:   date_from,
              }
            end

            it "returns nothing" do
              expect(json).to be_empty
            end
          end
        end
      end
    end
  end
end
