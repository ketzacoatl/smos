{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}

module Smos.Cursor.Header
  ( HeaderCursor(..)
  , makeHeaderCursor
  , rebuildHeaderCursor
  , headerCursorInsert
  , headerCursorAppend
  , headerCursorRemove
  , headerCursorDelete
  , headerCursorSelectStart
  , headerCursorSelectEnd
  , headerCursorSelectPrev
  , headerCursorSelectNext
  ) where

import GHC.Generics (Generic)

import Data.Maybe
import Data.Validity

import Control.Monad

import Lens.Micro

import Cursor.Text
import Cursor.Types

import Smos.Data.Types

newtype HeaderCursor =
  HeaderCursor
    { headerCursorTextCursor :: TextCursor
    }
  deriving (Show, Eq, Generic)

instance Validity HeaderCursor where
  validate tc@HeaderCursor {..} =
    mconcat
      [ genericValidate tc
      , decorate "The resulting Header is valid" $
        case parseHeader (rebuildTextCursor headerCursorTextCursor) of
          Left err -> invalid err
          Right t -> validate t
      ]

headerCursorTextCursorL :: Lens' HeaderCursor TextCursor
headerCursorTextCursorL =
  lens headerCursorTextCursor $ \headerc textc -> headerc {headerCursorTextCursor = textc}

-- fromJust is safe because makeTextCursor only works with text without newlines,
-- and that is one of the validity requirements of 'Header'.
makeHeaderCursor :: Header -> HeaderCursor
makeHeaderCursor = HeaderCursor . fromJust . makeTextCursor . headerText

-- fromJust is safe because 'header' only returns Nothing if the text cursor contains
-- an invalid header and it's one of the validity constraints that it doesn't.
rebuildHeaderCursor :: HeaderCursor -> Header
rebuildHeaderCursor = fromJust . header . rebuildTextCursor . headerCursorTextCursor

headerCursorInsert :: Char -> HeaderCursor -> Maybe HeaderCursor
headerCursorInsert c = headerCursorTextCursorL (textCursorInsert c) >=> constructValid

headerCursorAppend :: Char -> HeaderCursor -> Maybe HeaderCursor
headerCursorAppend c = headerCursorTextCursorL (textCursorAppend c) >=> constructValid

headerCursorRemove :: HeaderCursor -> Maybe (DeleteOrUpdate HeaderCursor)
headerCursorRemove = focusPossibleDeleteOrUpdate headerCursorTextCursorL textCursorRemove

headerCursorDelete :: HeaderCursor -> Maybe (DeleteOrUpdate HeaderCursor)
headerCursorDelete = focusPossibleDeleteOrUpdate headerCursorTextCursorL textCursorDelete

headerCursorSelectStart :: HeaderCursor -> HeaderCursor
headerCursorSelectStart = headerCursorTextCursorL %~ textCursorSelectStart

headerCursorSelectEnd :: HeaderCursor -> HeaderCursor
headerCursorSelectEnd = headerCursorTextCursorL %~ textCursorSelectEnd

headerCursorSelectPrev :: HeaderCursor -> Maybe HeaderCursor
headerCursorSelectPrev = headerCursorTextCursorL textCursorSelectPrev

headerCursorSelectNext :: HeaderCursor -> Maybe HeaderCursor
headerCursorSelectNext = headerCursorTextCursorL textCursorSelectNext
