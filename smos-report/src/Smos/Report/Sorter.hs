{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Smos.Report.Sorter where

import GHC.Generics (Generic)

import Data.Aeson
import Data.Char as Char
import Data.List
import qualified Data.Map as M
import Data.Ord
import qualified Data.Text as T
import Data.Text (Text)
import Data.Validity
import Data.Void

import Control.Monad

import Text.Megaparsec
import Text.Megaparsec.Char

import Smos.Data

import Smos.Report.Path
import Smos.Report.Time hiding (P)

data Sorter
  = ByFile
  | ByTag Tag
  | ByProperty PropertyName
  | ByPropertyTime PropertyName
  | Reverse Sorter
  | AndThen Sorter Sorter
  deriving (Show, Eq, Generic)

instance Validity Sorter

instance FromJSON Sorter where
  parseJSON v =
    flip (withText "Sorter") v $ \t ->
      case parseSorter t of
        Nothing -> fail "could not parse sorter."
        Just f -> pure f

instance ToJSON Sorter where
  toJSON = toJSON . renderSorter

sorterSortList :: Sorter -> [(RootedPath, Entry)] -> [(RootedPath, Entry)]
sorterSortList s = sortBy $ \(rpa, ea) (rpb, eb) -> sorterOrdering s rpa ea rpb eb

sorterOrdering :: Sorter -> RootedPath -> Entry -> RootedPath -> Entry -> Ordering
sorterOrdering s_ rpa fca_ rpb fcb_ = go s_ fca_ fcb_
  where
    go s ea eb =
      case s of
        ByFile -> comparing resolveRootedPath rpa rpb
        ByTag t -> comparing ((t `elem`) . entryTags) ea eb
        ByPropertyTime pn ->
          comparing (\e -> M.lookup pn (entryProperties e) >>= (time . propertyValueText)) ea eb
        ByProperty pn -> comparing (M.lookup pn . entryProperties) ea eb
        Reverse s' ->
          (\case
             GT -> LT
             EQ -> EQ
             LT -> GT) $
          go s' ea eb
        AndThen s1 s2 -> go s1 ea eb <> go s2 ea eb

parseSorter :: Text -> Maybe Sorter
parseSorter = parseMaybe sorterP

type P = Parsec Void Text

sorterP :: P Sorter
sorterP =
  try byFileP <|> try byTagP <|> try byPropertyAsTimeP <|> try byPropertyP <|> try reverseP <|>
  andThenP

byFileP :: P Sorter
byFileP = do
  void $ string' "file"
  pure ByFile

byTagP :: P Sorter
byTagP = do
  void $ string' "tag:"
  ByTag <$> tagP

byPropertyP :: P Sorter
byPropertyP = do
  void $ string' "property:"
  ByProperty <$> propertyNameP

byPropertyAsTimeP :: P Sorter
byPropertyAsTimeP = do
  void $ string' "property-as-time:"
  ByPropertyTime <$> propertyNameP

reverseP :: P Sorter
reverseP = do
  void $ string' "reverse:"
  Reverse <$> sorterP

andThenP :: P Sorter
andThenP = do
  void $ char '('
  s1 <- sorterP
  void $ string' " then "
  s2 <- sorterP
  void $ char ')'
  pure $ AndThen s1 s2

tagP :: P Tag
tagP = do
  s <- many (satisfy $ \c -> Char.isPrint c && not (Char.isSpace c) && not (Char.isPunctuation c))
  either fail pure $ parseTag $ T.pack s

propertyNameP :: P PropertyName
propertyNameP = do
  s <- many (satisfy $ \c -> Char.isPrint c && not (Char.isSpace c) && not (Char.isPunctuation c))
  either fail pure $ parsePropertyName $ T.pack s

renderSorter :: Sorter -> Text
renderSorter f =
  case f of
    ByFile -> "file"
    ByTag t -> "tag:" <> tagText t
    ByProperty pn -> "property:" <> propertyNameText pn
    ByPropertyTime pn -> "property-as-time:" <> propertyNameText pn
    Reverse s' -> "reverse:" <> renderSorter s'
    AndThen s1 s2 -> T.concat ["(", renderSorter s1, " then ", renderSorter s2, ")"]
