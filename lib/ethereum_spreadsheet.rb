require 'csv'
require 'http'
require 'active_support/core_ext/enumerable'

class EthereumSpreadsheet
  BASE_MORALIS_ENDPOINT = "https://deep-index.moralis.io/api/v2.2/nft/getMultipleNFTs?chain=eth"
  OPENSEA_SHARED_STOREFRONT_ADDRESS = "0x495f947276749ce646f68ac8c248420045cb7b5e"
  MAX_TOKENS_PER_REQUEST = 25
  DECIMAL_TOKEN_STEP = 1099511627776

  attr_reader :first_token_id, :last_token_id

  def initialize(first_token_id, last_token_id)
    @first_token_id = first_token_id.to_i
    @last_token_id = last_token_id.to_i
  end

  # Since the API has a limit of 25 tokens per request, we need to make multiple requests to get all the tokens.
  # We can calculate the number of requests we need to make by dividing the total number of tokens by the maximum number of tokens per request.
  # We can then use the `batches` method to generate the number of requests we need to make.
  # We need to generate a request body for each request, which will contain the token addresses we want to fetch.
  def body_for_batch(batch)
    {
      tokens: batch.map do |current_token_id|
        {
          token_address: OPENSEA_SHARED_STOREFRONT_ADDRESS,
          token_id: current_token_id.to_s
        }
      end
    }
  end

  def tokens
    (first_token_id..last_token_id).step(DECIMAL_TOKEN_STEP).to_a
  end

  def generate
    owners = tokens.each_slice(MAX_TOKENS_PER_REQUEST).flat_map do |batch|
      result = HTTP
        .headers("X-API-KEY" => ENV.fetch("MORALIS_API_KEY"))
        .post(BASE_MORALIS_ENDPOINT, json: body_for_batch(batch))
        .parse(:json)

      puts result
      sleep(1)  # Sleep for 1 second to avoid rate limiting

      result.pluck("owner_of")
    end

    token_holders = owners.tally.to_a

    content = CSV.generate do |csv|
      csv << ["ownerAddress", "value"]
      token_holders.each do |row|
        csv << row
      end
    end
  end
end
