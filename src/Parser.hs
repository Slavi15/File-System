module Parser where

import Data.Char (isSpace)
import Control.Applicative

import Command

newtype Parser a = Parser { runParser :: String -> Maybe (String, a) }

instance Functor Parser where
    fmap f (Parser p) = Parser f'
        where
            f' input = do
                (input', x) <- p input
                Just (input', f $ x)

instance Applicative Parser where
    pure x = Parser f
        where 
            f input = Just (input, x)

    (Parser p1) <*> (Parser p2) = Parser f
        where 
            f input = do
                (input', f') <- p1 input
                (input'', a) <- p2 input'
                Just (input'', f' $ a)

instance Alternative Parser where
    empty = Parser $ \_ -> Nothing
    (Parser p1) <|> (Parser p2) = Parser f
        where
            f input = p1 input <|> p2 input

charParser :: Char -> Parser Char
charParser ch = Parser f
    where
        f :: String -> Maybe (String, Char)
        f (x : xs)
            | x == ch = Just (xs, x)
            | otherwise = Nothing
        f [] = Nothing

stringParser :: String -> Parser String
stringParser = sequenceA . map charParser

spanParser :: (Char -> Bool) -> Parser String
spanParser f = Parser f'
    where
        f' input =
            let (token, rest) = span f input
            in Just (rest, token)

ws :: Parser String
ws = spanParser isSpace

slashParser :: Parser String
slashParser = charParser '/' *> spanParser (/= '/')

getNextDirectory :: String -> Maybe (String, String)
getNextDirectory "" = Just ("", "")
getNextDirectory path = runParser slashParser path

pwdParser :: Parser Command
pwdParser = (\_ -> PWDCommand) <$> stringParser "pwd"

cdParser :: Parser Command
cdParser = (\_ -> CDCommand) <$> stringParser "cd"

lsParser :: Parser Command
lsParser = (\_ -> LSCommand) <$> stringParser "ls"

catParser :: Parser Command
catParser = (\_ -> CATCommand) <$> stringParser "cat"

dirParser :: Parser Command
dirParser = f <$> (stringParser "mkdir" <|> stringParser "touch")
    where
        f "mkdir" = DIRCommand MkDir
        f "touch" = DIRCommand Touch
        f _ = undefined

rmParser :: Parser Command
rmParser = (\_ -> RMCommand) <$> stringParser "rm"

quitParser :: Parser Command
quitParser = (\_ -> QUITCommand) <$> stringParser ":q"

cmdParser :: Parser Command
cmdParser = pwdParser <|> cdParser <|> lsParser <|> catParser <|> dirParser <|> rmParser <|> quitParser

parseCommand :: String -> Maybe (String, Command)
parseCommand = runParser $ cmdParser <* ws