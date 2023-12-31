##
## Definition of Methods
##

## helper for vector dividing
.div <- function(x, d=1) {
    delta <- ceiling(length(x) / d)
    y <- lapply(seq_len(d), function(i){
        as.vector(na.omit(x[((i-1)*delta+1):(i*delta)]))
    })
    return(y)
}

setMethod("show",
    "LRBaseDb",
    function(object){
        print("##### class ####")
        print(class(object))
        print("##### connection #####")
        print(object$conn)
        print("##### sqlite file #####")
        print(object$dbfile)
    }
)

# columns
setMethod("columns",
    "LRBaseDb",
    function(x) {
        return(dbGetQuery(dbconn(x),"PRAGMA TABLE_INFO(DATA);")$name)
    }
)

# keytypes
setMethod("keytypes",
    "LRBaseDb",
    function(x) {
        return(dbGetQuery(dbconn(x),"PRAGMA TABLE_INFO(DATA);")$name)
    }
)

# keys
setMethod("keys",
    "LRBaseDb",
    function(x, keytype){
        query <- paste0("SELECT ", keytype, " FROM DATA;")
        k     <- unlist(unique(dbGetQuery(x$conn, query)))
        names(k) <- NULL
        return(k)
    }
)

# select
setMethod("select",
    "LRBaseDb",
    function(x, keys, columns, keytype){
        c <- paste(columns, collapse=",")
        keys <- paste0('"', keys, '"')
        ke <- paste(keytype, keys, sep ="=")
        if(length(ke) >= 1000) {
            no.chunk <- ceiling(length(keys)/500)
            ke_loc <- .div(seq_along(ke), no.chunk)
            kee <- lapply(ke_loc, function(x){
                paste(ke[x], collapse=" OR ")
                })
        }else{
            kee <- paste(ke, sep="", collapse=" OR ")
        }

        # SQLs
        kk <- lapply(kee, function(i) {
            query <- paste0("SELECT ", c, " FROM DATA WHERE ", i)
            dbGetQuery(x$conn, query)
        })
        kk <- do.call(rbind, kk)
        return(unique(kk))
    }
)


## dbconn
setMethod("dbconn",
    "LRBaseDb",
    function(x){
        return(x$conn)
    }
)

## dbfile
setMethod("dbfile",
    "LRBaseDb",
    function(x){
      return(x$dbfile)
    }
)

## dbschema
setMethod("dbschema",
    "LRBaseDb",
    function(x){
        return(dbGetQuery(x$conn, "SELECT * FROM sqlite_master;")$sql)
    }
)

## dbInfo
setMethod("dbInfo",
    "LRBaseDb",
    function(x){
        return(dbGetQuery(x$conn, "SELECT * FROM METADATA;"))
    }
)

## species
setMethod("species",
    "LRBaseDb",
    function(object) {
        return(dbGetQuery(object$conn,
            'SELECT value FROM METADATA where name = "SPECIES";')[1,])
    }
)

## lrNomenclature
setMethod("lrNomenclature",
    "LRBaseDb",
    function(x) {
        return(dbGetQuery(x$conn,
            'SELECT value FROM METADATA where name = "ORGANISM";')[1,])
    }
)

## lrListDatabases
setMethod("lrListDatabases",
    "LRBaseDb",
    function(x) {
        return(dbGetQuery(x$conn, 'SELECT DISTINCT SOURCEDB FROM DATA;'))
    }
)

## lrVersion
setMethod("lrVersion",
    "LRBaseDb",
    function(x){
        return(dbGetQuery(x$conn,
            'SELECT * FROM METADATA where name = "LRVERSION";')[1,])
    }
)
