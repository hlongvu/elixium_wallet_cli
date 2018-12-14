defmodule ElixiumWalletCli.AES do

  @aad "AES256GCM" # Use AES 256 Bit Keys for Encryption.

  @spec encrypt(any, String.t) :: String.t
  def encrypt(plaintext, key) do

    key = :crypto.hash(:sha256, key)

    iv = :crypto.strong_rand_bytes(16) # create random Initialisation Vector
    {ciphertext, tag} =
      :crypto.block_encrypt(:aes_gcm, key, iv, {@aad, to_string(plaintext), 16})
    iv <> tag <> ciphertext # "return" iv with the cipher tag & ciphertext
  end

  @spec decrypt(String.t, String.t) :: {String.t, number}
  def decrypt(ciphertext, key) do # patern match on binary to split parts:
    key = :crypto.hash(:sha256, key)

    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext
    :crypto.block_decrypt(:aes_gcm, key, iv, {@aad, ciphertext, tag})
  end

end