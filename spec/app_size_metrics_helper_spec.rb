require_relative './spec_helper'

describe Fastlane::WPMRT::AppSizeMetricsHelper do
  describe '#to_h' do
    it 'generates the right payload from raw data' do
      metrics_helper = described_class.new({
                                             'Group Metadata 1': 'Group Value 1',
                                             'Group Metadata 2': 'Group Value 2'
                                           })
      metrics_helper.add_metric(name: 'Metric 1', value: 12_345, meta: { m1a: 'Metric 1 Metadata A' })
      metrics_helper.add_metric(name: 'Metric 2', value: 67_890)
      metrics_helper.add_metric(name: 'Metric 3', value: 13_579, meta: { m3a: 'Metric 3 Metadata A', m3b: 'Metric 3 Metadata B' })

      expected_hash = {
        meta: [
          { name: 'Group Metadata 1', value: 'Group Value 1' },
          { name: 'Group Metadata 2', value: 'Group Value 2' },
        ],
        metrics: [
          { name: 'Metric 1', value: 12_345, meta: [{ name: 'm1a', value: 'Metric 1 Metadata A' }] },
          { name: 'Metric 2', value: 67_890 },
          { name: 'Metric 3', value: 13_579, meta: [{ name: 'm3a', value: 'Metric 3 Metadata A' }, { name: 'm3b', value: 'Metric 3 Metadata B' }] },
        ]
      }
      expect(metrics_helper.to_h).to eq(expected_hash)
    end

    it 'removes `nil` values in metadata' do
      metrics_helper = described_class.new({
                                             'Group Metadata 1': 'Group Value 1',
                                             'Group Metadata 2': nil,
                                             'Group Metadata 3': 'Group Value 3'
                                           })
      metrics_helper.add_metric(name: 'Metric 1', value: 12_345, meta: { m1a: 'Metric 1 Metadata A', m1b: nil, m1c: 'Metric 1 Metadata C' })
      metrics_helper.add_metric(name: 'Metric 2', value: 67_890, meta: { m2a: nil })
      metrics_helper.add_metric(name: 'Metric 3', value: 13_579, meta: { m3a: 'Metric 3 Metadata A', m3b: 'Metric 3 Metadata B' })

      expected_hash = {
        meta: [
          { name: 'Group Metadata 1', value: 'Group Value 1' },
          { name: 'Group Metadata 3', value: 'Group Value 3' },
        ],
        metrics: [
          { name: 'Metric 1', value: 12_345, meta: [{ name: 'm1a', value: 'Metric 1 Metadata A' }, { name: 'm1c', value: 'Metric 1 Metadata C' }] },
          { name: 'Metric 2', value: 67_890 },
          { name: 'Metric 3', value: 13_579, meta: [{ name: 'm3a', value: 'Metric 3 Metadata A' }, { name: 'm3b', value: 'Metric 3 Metadata B' }] },
        ]
      }
      expect(metrics_helper.to_h).to eq(expected_hash)
    end
  end

  describe '#send_metrics' do
    let(:metrics_helper) do
      metrics_helper = described_class.new({
                                             'Group Metadata 1': 'Group Value 1',
                                             'Group Metadata 2': 'Group Value 2'
                                           })
      metrics_helper.add_metric(name: 'Metric 1', value: 12_345, meta: { m1a: 'Metric 1 Metadata A' })
      metrics_helper.add_metric(name: 'Metric 2', value: 67_890)
      metrics_helper.add_metric(name: 'Metric 3', value: 13_579, meta: { m3a: 'Metric 3 Metadata A', m3b: 'Metric 3 Metadata B' })
      metrics_helper
    end
    let(:expected_data) do
      {
        meta: [
          { name: 'Group Metadata 1', value: 'Group Value 1' },
          { name: 'Group Metadata 2', value: 'Group Value 2' },
        ],
        metrics: [
          { name: 'Metric 1', value: 12_345, meta: [{ name: 'm1a', value: 'Metric 1 Metadata A' }] },
          { name: 'Metric 2', value: 67_890 },
          { name: 'Metric 3', value: 13_579, meta: [{ name: 'm3a', value: 'Metric 3 Metadata A' }, { name: 'm3b', value: 'Metric 3 Metadata B' }] },
        ]
      }.to_json
    end

    context 'when using file:// scheme for the URL' do
      it 'writes the payload uncompressed to a file when disabling gzip' do
        in_tmp_dir do |tmp_dir|
          output_file = File.join(tmp_dir, 'payload.json')
          file_url = File.join('file://localhost/', output_file)

          code = metrics_helper.send_metrics(to: file_url, api_token: nil, use_gzip: false)

          expect(code).to eq(201)
          expect(File).to exist(output_file)
          uncompressed_data = File.read(output_file)
          expect(uncompressed_data).to eq(expected_data)
        end
      end

      it 'writes the payload compressed to a file when enabling gzip' do
        in_tmp_dir do |tmp_dir|
          output_file = File.join(tmp_dir, 'payload.json.gz')
          file_url = File.join('file://localhost/', output_file)

          code = metrics_helper.send_metrics(to: file_url, api_token: nil, use_gzip: true)

          expect(code).to eq(201)
          expect(File).to exist(output_file)
          uncompressed_data = Zlib::GzipReader.open(output_file, &:read)
          expect(uncompressed_data).to eq(expected_data)
        end
      end
    end

    context 'when using non-file:// scheme for the URL' do
      let(:api_url) { 'https://fake-metrics-server/api/grouped-metrics' }
      let(:token) { 'fake#tokn' }

      it 'sends the payload uncompressed to the server and with the right headers when disabling gzip' do
        expected_headers = {
          Authorization: "Bearer #{token}",
          Accept: 'application/json',
          'Content-Type': 'application/json'
        }
        last_received_body = nil
        stub = stub_request(:post, api_url).with(headers: expected_headers) do |req|
          last_received_body = req.body
        end.to_return(status: 201)

        code = metrics_helper.send_metrics(to: api_url, api_token: token, use_gzip: false)

        expect(code).to eq(201)
        expect(stub).to have_been_made.once
        expect(last_received_body).to eq(expected_data)
      end

      it 'sends the payload compressed to the server and with the right headers when enabling gzip' do
        expected_headers = {
          Authorization: "Bearer #{token}",
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'Content-Encoding': 'gzip'
        }
        last_received_body = nil
        stub = stub_request(:post, api_url).with(headers: expected_headers) do |req|
          last_received_body = req.body
        end.to_return(status: 201)

        code = metrics_helper.send_metrics(to: api_url, api_token: token, use_gzip: true)

        expect(code).to eq(201)
        expect(stub).to have_been_made.once
        expect do
          last_received_body = Zlib.gunzip(last_received_body)
        end.not_to raise_error
        expect(last_received_body).to eq(expected_data)
      end
    end
  end
end
