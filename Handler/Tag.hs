module Handler.Tag where

import qualified Database.Esqueleto as E
import           Data.Slug (Slug, unSlug)
import           Import


getTagListR :: Handler Html
getTagListR = do
    tags <- fmap (zip [0::Int ..] . (map (\(E.Value v,E.Value i) -> (v,i::Int)))) $ runDB $
        E.select $ E.from $ \tag -> do
            E.groupBy (tag E.^. TagTag)
            E.orderBy [E.desc (E.count (tag E.^. TagTag) :: E.SqlExpr (E.Value Int))]
            return (tag E.^. TagTag, E.count (tag E.^. TagTag))
    defaultLayout $ do
        setTitle "Stackage tags"
        $(widgetFile "tag-list")

getTagR :: Slug -> Handler Html
getTagR tagSlug = do
    packages <- fmap (map (\(E.Value t,E.Value s) -> (t,strip s))) $ runDB $
        E.select $ E.from $ \(tag,meta) -> do
            E.where_ (tag E.^. TagTag E.==. E.val tagSlug E.&&.
                      meta E.^. MetadataName E.==. tag E.^. TagPackage)
            E.orderBy [E.asc (tag E.^. TagPackage)]
            return (tag E.^. TagPackage,meta E.^. MetadataSynopsis)
    let tag = unSlug tagSlug
    defaultLayout $ do
          setTitle $ "Stackage tag"
          $(widgetFile "tag")
  where strip x = fromMaybe x (stripSuffix "." x)