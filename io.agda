module io where

open import bool
open import char
open import list
open import string
open import unit

----------------------------------------------------------------------
-- datatypes
----------------------------------------------------------------------

postulate
  IO : Set → Set

{-# COMPILED_TYPE IO IO #-}
{-# BUILTIN IO IO #-}

----------------------------------------------------------------------
-- syntax
----------------------------------------------------------------------

infixl 1 _>>=_
infixl 1 _>>_

----------------------------------------------------------------------
-- postulated operations
----------------------------------------------------------------------

postulate
  return : ∀ {A : Set} → A → IO A
  _>>=_  : ∀ {A B : Set} → IO A → (A → IO B) → IO B

{-# COMPILED return (\ _ -> return )   #-}
{-# COMPILED _>>=_  (\ _ _ -> (>>=)) #-}

postulate
  putStr : string -> IO ⊤

  -- Reads a file, which is assumed to be finite. 
  readFiniteFile : string → IO string

  writeFile : string → string → IO ⊤

  -- set output to UTF-8 for Windows
  
  initializeStdoutToUTF8 : IO ⊤

  -- set newline mode for Windows
  
  setStdoutNewlineMode : IO ⊤

  -- writing to files using Handles
  Handle : Set
  withWritableFile : ∀{r : Set} → string → (Handle → IO r) → IO r
  hPutStr : Handle → string → IO ⊤  
  stdout : Handle 

  getLine : IO string

{-# IMPORT System.IO #-}
{-# COMPILED_TYPE Handle System.IO.Handle #-}
{-# COMPILED withWritableFile  (\ _ f k -> System.IO.withFile f System.IO.WriteMode k)                #-}
{-# COMPILED hPutStr         System.IO.hPutStr                #-}
{-# COMPILED stdout         System.IO.stdout                #-}

private
  data simple-list (A : Set) : Set where
    nil : simple-list A
    cons : A → simple-list A → simple-list A
  
  simple-list-to-𝕃 : ∀ {A : Set} → simple-list A → 𝕃 A
  simple-list-to-𝕃 nil = []
  simple-list-to-𝕃 (cons x xs) = x :: (simple-list-to-𝕃 xs)

{-# COMPILED_DATA simple-list ([]) [] (:) #-}

private
  postulate
    privGetArgs : IO (simple-list string)
    privDoesFileExist : string → IO 𝔹
    privCreateDirectoryIfMissing : 𝔹 → string → IO ⊤
    privTakeDirectory : string → string
    privTakeFileName : string → string
    privCombineFileNames : string → string → string
    privForceFileRead : string {- the contents of the file, not the file name -} → IO ⊤

    privGetHomeDirectory : IO string

{-# IMPORT Control.DeepSeq #-}
{-# COMPILED putStr         putStr                #-}
{-# COMPILED readFiniteFile (\x -> do inh <- System.IO.openFile x System.IO.ReadMode; System.IO.hSetEncoding inh System.IO.utf8; fileAsString <- System.IO.hGetContents inh; Control.DeepSeq.rnf fileAsString `seq` System.IO.hClose inh; return fileAsString) #-}
{-# COMPILED writeFile (\path -> (\str -> do outh <- System.IO.openFile path System.IO.WriteMode; System.IO.hSetNewlineMode outh System.IO.noNewlineTranslation; System.IO.hSetEncoding outh System.IO.utf8; System.IO.hPutStr outh str; System.IO.hFlush outh; System.IO.hClose outh; return () )) #-}
{-# COMPILED initializeStdoutToUTF8  System.IO.hSetEncoding System.IO.stdout System.IO.utf8 #-}
{-# COMPILED setStdoutNewlineMode System.IO.hSetNewlineMode System.IO.stdout System.IO.universalNewlineMode #-}
{-# IMPORT System.Environment #-}
{-# COMPILED privGetArgs System.Environment.getArgs #-}
{-# IMPORT System.Directory #-}
{-# COMPILED privForceFileRead (\ contents -> seq (length contents) (return ())) #-}
{-# COMPILED privDoesFileExist System.Directory.doesFileExist #-}
{-# COMPILED privCreateDirectoryIfMissing System.Directory.createDirectoryIfMissing #-}
{-# IMPORT System.FilePath #-}
{-# COMPILED privTakeDirectory System.FilePath.takeDirectory #-}
{-# COMPILED privTakeFileName System.FilePath.takeFileName #-}
{-# COMPILED privCombineFileNames System.FilePath.combine #-}
{-# COMPILED getLine getLine #-}
{-# COMPILED privGetHomeDirectory System.Directory.getHomeDirectory #-}

getArgs : IO (𝕃 string)
getArgs = privGetArgs >>= (λ args → return (simple-list-to-𝕃 args))

doesFileExist : string → IO 𝔹
doesFileExist = privDoesFileExist

createDirectoryIfMissing : 𝔹 → string → IO ⊤
createDirectoryIfMissing = privCreateDirectoryIfMissing

takeDirectory : string → string
takeDirectory = privTakeDirectory

takeFileName : string → string
takeFileName = privTakeFileName

combineFileNames : string → string → string
combineFileNames = privCombineFileNames

forceFileRead : string {- the contents of the file, not the file name -} → IO ⊤
forceFileRead = privForceFileRead

getHomeDirectory : IO string
getHomeDirectory = privGetHomeDirectory

postulate
  fileIsOlder : string → string → IO 𝔹
  canonicalizePath : string → IO string 
{-# COMPILED fileIsOlder (\ s1 s2 -> (System.Directory.getModificationTime s1) >>= \ t1 -> (System.Directory.getModificationTime s2) >>= \ t2 -> return (t1 < t2)) #-}
{-# COMPILED canonicalizePath System.Directory.canonicalizePath #-}

----------------------------------------------------------------------
-- defined operations
----------------------------------------------------------------------

_>>_ : ∀ {A B : Set} → IO A → IO B → IO B
x >> y = x >>= (λ q -> y)

base-filenameh : 𝕃 char → 𝕃 char
base-filenameh [] = []
base-filenameh ('.' :: cs) = cs
base-filenameh (_ :: cs) = base-filenameh cs

-- return the part of the string up to the last (rightmost) period ('.'); so for "foo.txt" return "foo"
base-filename : string → string
base-filename s = 𝕃char-to-string (reverse (base-filenameh (reverse (string-to-𝕃char s))))

