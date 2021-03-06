{-# LANGUAGE OverloadedStrings #-}

module Smos.Server.Handler.PostRegisterSpec
  ( spec
  ) where

import Test.Hspec
import Test.Validity

import Smos.Client
import Smos.Server.TestUtils

spec :: Spec
spec =
  serverSpec $
  describe "PostRegister" $
  it "works for any username and password" $ \cenv ->
    forAllValid $ \register -> do
      NoContent <- testClientOrErr cenv (clientPostRegister register)
      pure ()
