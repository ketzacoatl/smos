module Smos.Report
    ( report
    ) where

import Smos.Report.Next
import Smos.Report.OptParse
import Smos.Report.Waiting

report :: IO ()
report = do
    (disp, set) <- getInstructions
    execute disp set

execute :: Dispatch -> Settings -> IO ()
execute DispatchWaiting set = waiting set
execute DispatchNext set = next set
