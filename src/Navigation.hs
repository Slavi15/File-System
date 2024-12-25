{-# LANGUAGE LambdaCase #-}
module Navigation where

import Core.FileSystem ( FileSystem(..) )

import Data.Maybe (maybeToList)
import Data.List (find)

import Parser (getNextDirectory)
import Output (printDirectory, printEntity, printCDCommand)
import Utility (getName)

pwd :: [FileSystem] -> String
pwd = printDirectory

cd :: String -> [FileSystem] -> Maybe [FileSystem]
cd input fs = case getNextDirectory input of
    Just ("", "") -> Just fs
    Just (rest, "..") ->
        case goToParentDirectory fs of
            (Just parentDirectory) -> cd rest parentDirectory
            Nothing -> Nothing
    Just (rest, curr) ->
        case goToSubDirectory curr fs of
            (Just subDirectory) -> cd rest (subDirectory : fs)
            Nothing -> Nothing
    Nothing -> Nothing

ls :: String -> Maybe FileSystem -> String
ls input fs = case cd input (maybeToList fs) of
    Just ((MkDirectory _ contents) : _) -> concatMap printEntity contents
    Nothing -> "Invalid directory!\n"

goToParentDirectory :: [FileSystem] -> Maybe [FileSystem]
goToParentDirectory (_ : fs) = Just fs
goToParentDirectory [] = Nothing

goToSubDirectory :: String -> [FileSystem] -> Maybe FileSystem
goToSubDirectory name (MkDirectory _ contents : _) =
    find (\case
        MkDirectory directoryName _ -> name == directoryName
        _ -> False) contents
goToSubDirectory _ _ = Nothing