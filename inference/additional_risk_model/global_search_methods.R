# Load the panel pomp object  --------------------------------------
if(file.exists(pomp_filename)){
  load(pomp_filename)
}

# Set the parameters -------------------------------------------------
guess.shared <- guess[names(guess) %in% names(coef(panelHPVShared)$shared)]
guess.specific <- guess[!(names(guess) %in% names(coef(panelHPVShared)$shared))]
start <- Sys.time()
mf <- mif2(
  panelHPVShared,
  Nmif = n_mif,
  shared.start = unlist(guess.shared),
  specific.start = matrix(
    data =  guess.specific,
    nrow = length(guess.specific),
    ncol = length(panelHPVShared@unit.objects),
    dimnames = list(names(guess.specific),
                    names(panelHPVShared@unit.objects))                 
  ),
  rw.sd = rw_sd_vec,
  cooling.type = "geometric",
  cooling.fraction.50 = cooling_rate,
  Np = n_particles
)
end <- Sys.time()
filename <- chain_filename
save(mf, file = filename)

## Evaluate the likelihood ----------------------------------------------------------------
if(evaluate_Lhood == TRUE){
  ll <- logmeanexp(replicate(n_reps_pfilter,logLik(pfilter(mf,Np=n_particles_pfilter))),se=TRUE)
  output <- (data.frame(as.list(coef(mf)$shared),loglik=ll[1],loglik_se=ll[2], n_mif = n_mif_updated, n_part = n_particles_pfilter, chain = chainId))
  write.table(output, file = output_filename, sep = ",",col.names = FALSE, append=TRUE)
  db <- dbConnect(SQLite(), results_db)
  dbWriteTable(db, table_name, output, append = T)
  dbDisconnect(db)
}



