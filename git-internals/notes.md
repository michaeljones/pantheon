
# Git Internals

## Notes

- Source Code Control System (SCCS) - 1973
- Concurrent Versions System - 1990
- ClearCase - 1992
- BitKeeper - 2000
- Subversion - 2000
- Darcs - 2003
- Git - 2005
- Fossil - 2006
- Mercurial - 2005
- Pijul - 2017


## Linux

- Used to use tarballs & patches
- Switched to bitkeeper - free licenses
- Reverse engineered bitkeeper
- Linus Torvalds create git

## Not the best interface

- Inconsisent
- Poorly named
- Confusing

- Some recent attempts to improve it

- Originally designed as a tool kit to create version control systems rather than a version control
  system itself

- Arguably largely popularised by Github's success

- Not great for binary data
- Not great for computer games & game assets
- Generally does a full repository clone - better to keep repositories manageable in size
- Significant work by big companies to make it scale for huge repositories but generally not used
  for mega-mono-repos
- 

## Internals

- Made up of an object graph where the connections are SHA1 references
- Content addressable file system
  - Know where to store something by its contents not by its name.

- Hash all the files in a directory to SHA1s. 
- Create a text file with a list of all the files and their SHA1s - hash that
- Recurse up the tree.
- Create a text file that references the SHA1 of the top of that tree and the SHA1 of any preceeding
  commits and hash that to get the SHA1 of the commit

## Progression

- If you change a file, then you get a new SHA1 for that file
- Which means a new SHA1 for that directory - but same SHA1 for other files
- Which means a new SHA1 for the directory above that, etc
- Which means a new commit SHA1

## History of your history

- If you have a new commit SHA1 then you don't have to change the SHA1 of the old commit - in fact
  you still have the old commit. 
- So if you edit a commit you get a fresh new commit without impact your old one
- This means all your old commits are still hanging around until they are cleaned up
- This means you have a history of your history

## Why is this useful?

- Having a history makes things feel safer

- The old reason we have source control, which is a history of our files, is so that we can be more
  confident in the changes we make. We can see what has changed and we can roll back if we're
  unhappy.

  This means we can be more carefree with the changes that we make to files because we have a safety
  net.

- If we have a history of our history then it means we can have a sense of confidence in editing the
  history itself. Because we can roll back if we make a mistake.

- It means we can be more carefree with the changes that we make to our history because we have a
  safety net.

## Why do we want to make changes to our history?

- If our history is maleable, then we can revise it. If we can revise it then we can fix mistakes.
  Accidental mistake and deliberate mistakes.

- What's an accidental mistake? A typo that use missed. A commented out line that you forgot to
  remove. A variable that could have an a clearer name. A commit message that doesn't include an
  extra piece of information that clarifies that change you made right down the bottom.

  - Why do this? We do this have a clean history and to safe our colleages that might be reviewing
    our large change a commit at a time and you don't want them to have to point out typos and
    mistakes if you can avoid it.

- What's a deliberate mistake? Well, thanks when we make deliberately bad commits because we know we
  can come back and fix them. This means you can make commits with bad commit messages. Commits with
  commented out code. Commits where the code doesn't compile. Commits where you want to safe a half
  implemented thought and then undo most it because another way might be better.

  - Why do we do this? To set ourselves free. To allow our thoughts to move faster and to reduce the
    friction in our workflow. 

    I used to work with SVN and there was very little in the way of editing capability and it meant
    that each commit was essentially etched in stone. You needed to make sure that it was perfect
    before you made it. This means that your taken out of you development/coding train of thought
    all the time and into 'source control caretaker' land. It massively increases friction around
    making changes and changing your line of thought.

    This kind of friction has an impact on our workflow. Linus says there are two kinds of
    interactions on a computer. The instantaneous ones and then everything else. The instantaneous
    ones get out of our way. They don't interrupt our flow. Everything else gives us pause for
    thought. Gives us a reason not to do that thing we're about to do because of the effort and
    trouble or slowness.

## Commands

- git cat-file -p <SHA1>

  To pretty print the contents of a git object.

## Talks

- Linus @ Google

