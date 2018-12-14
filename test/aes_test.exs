defmodule ElixiumWalletCli.AESTest do
  use ExUnit.Case
  alias ElixiumWalletCli.AES

  test ".encrypt includes the random IV in the value" do
    k = "password"
    <<iv::binary-16, ciphertext::binary>> = AES.encrypt("hello",k)

    assert String.length(iv) != 0
    assert String.length(ciphertext) != 0
    assert is_binary(ciphertext)
  end

  test "encrypt does not produce the same ciphertext twice" do
    k = "my_secret_pass"
    assert AES.encrypt("hello", k) != AES.encrypt("hello", k)
  end

  test "can decrypt a value" do
    k = "my_secret_pass"
    plaintext = "hello_hello" |> AES.encrypt(k) |> AES.decrypt(k)
    assert plaintext == "hello_hello"
  end

  test "does not decrypt if wrong password" do
    k = "my_secret_pass"
    w = "my_secret_pass2"
    input = "hello" |> AES.encrypt(k)

    ouput = input |> AES.decrypt(w)
#    IO.puts(ouput)
    assert ouput == :error
  end


end