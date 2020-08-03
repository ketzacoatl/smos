{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Smos.Calendar.Import.Render where

import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe
import Data.Tree
import Smos.Calendar.Import.Event
import Smos.Data

renderEvents :: [Event] -> SmosFile
renderEvents es = SmosFile $ map (\e -> Node e []) $ mapMaybe renderEvent es

renderEvent :: Event -> Maybe Entry
renderEvent ev@Event {..} = do
  let h = fromMaybe "Event without Summary" $ eventSummary >>= header
  mc <- mapM contents eventDescription
  let ts = renderTimestamps ev
  let e = (newEntry h) {entryContents = mc, entryTimestamps = ts}
  pure e

renderTimestamps :: Event -> Map TimestampName Timestamp
renderTimestamps Event {..} =
  M.fromList $
    concat
      [ [("BEGIN", ts) | Just ts <- [eventStart]],
        [("END", ts) | Just ts <- [eventEnd]]
      ]
