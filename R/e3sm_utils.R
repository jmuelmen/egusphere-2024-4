Rd <- 287
cp <- 1e3
Lv <- 2.5e6
g <- 9.8

#' Calculate 3D pressure from hybrid coordinates
#'
#' @export
calculate_p3d <- function(df) {
    df %>%
        dplyr::mutate(p = ps * hybm + p0 * hyam) %>%
        dplyr::mutate(dp = ps * dhybi + p0 * dhyai)
}

#' Find the nearest neighbors of each grid point
#'
#' @param grid.spacing max distance (km) between nearest neighbors; 204 is the value for ne30pg2
#' 
#' @export
neighbors <- function(df.grid,
                      grid.spacing = 204) {
    df.dist <- expand.grid(ncol1 = unique(df.grid$ncol),
                           ncol2 = unique(df.grid$ncol)) %>%
        dplyr::filter(ncol1 != ncol2) %>%
        dplyr::left_join(df.grid, by = c("ncol1" = "ncol")) %>%
        dplyr::rename_with(function(x) ifelse(grepl("^lon$|^lat$", x), sprintf("%s1", x), x)) %>%
        dplyr::left_join(df.grid, by = c("ncol2" = "ncol")) %>%
        dplyr::rename_with(function(x) ifelse(grepl("^lon$|^lat$", x), sprintf("%s2", x), x)) %>%
        dplyr::mutate(dist = plotutils::dist.gc(lon1, lon2, lat1, lat2))
    
    df.neighbors <- df.dist %>%
        dplyr::filter(dist < grid.spacing) %>%
        dplyr::group_by(ncol1) %>%
        dplyr::filter(dplyr::n() == 6) %>%
        dplyr::ungroup() %>%
        dplyr::select(ncol1, ncol2)
}

#' Rename variables
#'
#' @export
rename_fields <- function(df) {
    df %>%
        dplyr::rename(lts = th7001000,
                      qv = q,
                      ql = cldliq) %>%
        dplyr::mutate(prec = (precl + precc) * 1e3)
}

#' Rename variables
#'
#' @export
rename_fields_eamxx <- function(df) {
    df %>%
        dplyr::rename(t = T_mid,
                      ql = qc)
}

#' Rename variables
#'
#' @export
rename_fields_giss <- function(df) {
    df %>%
        dplyr::rename(lev = p,
                      z3 = z,
                      numliq = nclic,
                      cloud = cf,
                      ccn4 = ccn0p2,
                      qv = q,
                      ql = qcl,
                      theta = th,
                      p = p_3d) %>%
        dplyr::mutate(lcc = cldss_2d,
                      cdnc_ic = ssct_ncl,
                      lwp_ic = cLWPss / cldss_2d) %>%
        dplyr::mutate(p = p * 1e2,
                      omega = omega * 1e2,
                      dth_rad = dth_rad / 86400,
                      prec = prec / 86400,
                      shflx = -shflx,
                      qflx = -qflx,
                      lhflx = -lhflx,
                      numliq = numliq * 1e6) %>%
        dplyr::mutate(lcc = lcc * 1e-2,
                      cdnc_ic = cdnc_ic * 1e6,
                      lwp_ic = lwp_ic * 1e2 * 1e-3,
                      lwp = lwp * 1e-3)
}

#' Calculate thermodynamics (theta, theta_l, qt)
#'
#' @param df data.frame containing p, p0, t (temperature), qv, ql
#' 
#' @export
calculate_thermodynamics <- function(df) {
    df %>%
        dplyr::mutate(theta = if (exists("theta", where = .)) theta else t * (p0 / p) ^ (Rd / cp),
                      theta_l = theta - (theta / t) * Lv / cp * ql,
                      theta_e = equivalent_factor(t, p) * theta,
                      qt = qv + ql)
}

#' Find inversion
#'
#' @param df data_frame grouped by all coordinate variables except lev
#' @param default.type which inversion criterion gets returned as
#'     jk.pbl; "factor" returns all, with inv.type indicating the inversion type
#' 
#' @export
find_inversion <- function(df, default.type = "jk.tinv") {
    df %<>%
        dplyr::mutate(jk.tinv = max(which(diff(t) < 0)) + 1,
                      jk.theta = length(lev[lev < 700]) + which.min(diff(theta[lev >= 700]) / diff(lev[lev >= 700])) + 1, ## theta jump is negative in increasing lev direction
                      jk.qt = which.max(diff(qt) / diff(lev)) + 1, ## qt jump is positive in increasing lev direction
                      theta.jump = diff(theta)[jk.theta],
                      qt.jump = diff(qt)[jk.qt])

    switch(default.type,
           jk.tinv  = df %>% dplyr::mutate(jk.pbl = jk.tinv),
           jk.theta = df %>% dplyr::mutate(jk.pbl = jk.theta),
           jk.qt    = df %>% dplyr::mutate(jk.pbl = jk.qt),
           factor   = df %>% tidyr::gather(inv.type, jk.pbl, jk.tinv, jk.theta, jk.qt))
}

#' Find inversion
#'
#' @param df data_frame grouped by all coordinate variables except lev
#' @param default.type which inversion criterion gets returned as
#'     jk.pbl; "factor" returns all, with inv.type indicating the inversion type
#' 
#' @export
find_inversion_eamxx <- function(df, default.type = "jk.tinv") {
    df %<>%
        dplyr::mutate(jk.tinv = max(which(diff(t) < 0)) + 1,
                      jk.theta = length(lev[p < 700e2]) + which.min(diff(theta[p >= 700e2]) / diff(p[p >= 700e2])) + 1, ## theta jump is negative in increasing lev direction
                      jk.qt = which.max(diff(qt) / diff(p)) + 1, ## qt jump is positive in increasing lev direction
                      theta.jump = diff(theta)[jk.theta],
                      qt.jump = diff(qt)[jk.qt])

    switch(default.type,
           jk.tinv  = df %>% dplyr::mutate(jk.pbl = jk.tinv),
           jk.theta = df %>% dplyr::mutate(jk.pbl = jk.theta),
           jk.qt    = df %>% dplyr::mutate(jk.pbl = jk.qt),
           factor   = df %>% tidyr::gather(inv.type, jk.pbl, jk.tinv, jk.theta, jk.qt))
}

#' Match gradients above and below the inversion to provide PBL height
#'
#' @export
reconstruct_inversion <- function(p, z3, x, debug.plot = FALSE) {
    return(NA)
    
    df <- data.frame(p = p, z3 = z3, x = x, jk = 1 : length(p)) 

    ## find the two layers with the steepest gradients
    df.inversion <- df %>%
        dplyr::filter(p >= 700e2) %>%
        dplyr::mutate(gradient = (dplyr::lead(x) - x) / (dplyr::lead(z3) - z3),
                      abs.gradient = abs(gradient)) %>%
        ## dplyr::arrange(dplyr::desc(abs.gradient)) %>%
        ## dplyr::mutate(z.pbl = z3[jk == jk[1] + 1], jk.min = min(jk[1:2]), jk.max = max(jk[1:2])) %>%
        ## dplyr::arrange(jk) %>%
        ## dplyr::filter(jk >= jk.min - 1, jk <= jk.max + 1)
        dplyr::arrange(dplyr::desc(abs.gradient)) %>%
        dplyr::mutate(jk.pbl = jk[1] + 1, z.pbl = z3[jk == jk.pbl], jk.max = jk.pbl, jk.min = jk[1]) %>%
        dplyr::arrange(jk) %>%
        dplyr::filter(jk >= jk.min - 2, jk <= jk.max + 1)

    ## print(df.inversion)

    with(df.inversion, {
        zb <- z3[5]
        ## zm <- z3[3]
        zt <- z3[2]
        xb <- x[5]
        ## xm <- x[3]
        xt <- x[2]
        gb <- gradient[5]
        gt <- gradient[1]  ## note the different index here!

        delta.z <- zt - zb
        delta.x <- xt - xb
        ## A <- 0.5 * (xm - xb) * (zm - zb) + (xm - xb) * (zt - zb) + 0.5 * (xt - xm) * (zt - zm)
        A <- 0.5 * (x[4] - x[5]) * (z3[4] - z3[5]) +
            (x[4] - x[5]) * (z3[3] - z3[4]) + 0.5 * (x[3] - x[4]) * (z3[3] - z3[4]) +
            (x[3] - x[5]) * (z3[2] - z3[3]) + 0.5 * (x[2] - x[3]) * (z3[2] - z3[3]) 
        ## A <- 0.5 * delta.x * delta.z

        ## solve quadratic formula for interface pressure: z_i + 2 p.2 + q = 0 ==> z_i = -p.2 +- sqrt(p.2^2 - q)
        p.2 <- (gt * delta.z - delta.x) / (gb - gt)
        q <- (-gt * delta.z^2 + 2 * delta.z * delta.x - 2 * A) / (gb - gt)

        zi <- -p.2 + c(-1, 1) * sqrt(p.2^2 - q)

        ## sprintf("zb = %e\tzt = %e\txb = %e\txt = %e\tgb = %e\tgt = %e\tzi^2 + %e + %e == 0\tzi = %e or %e\n", zb, zt, xb, xt, gb, gt, 2 * p.2, q, zi[1], zi[2]) %>% cat

        zi.phys <- ifelse(zi >= 0 & zi <= delta.z, zi, NA) %>% ## check within physical bounds (makes sense)
            mean(na.rm = TRUE) ## use the mean if both solutions are physical (shouldn't happen)

        if (debug.plot) {
            print(ggplot(df %>% filter(p > 700e2), aes(z3 - zb, x - xb)) + geom_line() + geom_point() +
                  coord_flip() +
                  ## scale_x_reverse() +
                  geom_vline(xintercept = c(zb, zt) - zb, lty = "dashed") + geom_hline(yintercept = c(c(xb, xt) - xb, A / delta.z), lty = "dashed") +
                  geom_vline(xintercept = zi.phys, lty = "dotted") +
                  geom_abline(slope = gb, lty = "dotted") +
                  geom_abline(slope = gt, intercept = delta.x - delta.z * gt, lty = "dotted") +
                  geom_vline(xintercept = z.pbl - zb, col = "red", alpha = 0.5) ## +
                  ## geom_smooth(data = df %>% filter(p > 700e2, jk < jk.pbl))
                  )
        }
            
        ## print(zi.phys + zb)
        
        return(zi.phys + zb)
    })
}

#' Match gradients above and below the inversion to provide PBL height
#'
#' Same as reconstruct_inversion(), but returns PBL top pressure.
#'
#' For mass budgets, this function is more exact than
#' reconstruct_inversion(), which fails to account for density
#' variation within the inversion "zone of confusion".
#'
#' @export
reconstruct_inversion_pressure <- function(p, z3, x, debug.plot = FALSE) {
    return(NA)
    
    df <- data.frame(p = p, z3 = p, x = x, jk = 1 : length(p)) 

    ## find the two layers with the steepest gradients
    df.inversion <- df %>%
        dplyr::filter(p >= 700e2) %>%
        dplyr::mutate(gradient = (dplyr::lead(x) - x) / (dplyr::lead(z3) - z3),
                      abs.gradient = abs(gradient)) %>%
        ## dplyr::arrange(dplyr::desc(abs.gradient)) %>%
        ## dplyr::mutate(z.pbl = z3[jk == jk[1] + 1], jk.min = min(jk[1:2]), jk.max = max(jk[1:2])) %>%
        ## dplyr::arrange(jk) %>%
        ## dplyr::filter(jk >= jk.min - 1, jk <= jk.max + 1)
        dplyr::arrange(dplyr::desc(abs.gradient)) %>%
        dplyr::mutate(jk.pbl = jk[1] + 1, z.pbl = z3[jk == jk.pbl], jk.max = jk.pbl, jk.min = jk[1]) %>%
        dplyr::arrange(jk) %>%
        dplyr::filter(jk >= jk.min - 2, jk <= jk.max + 1)

    ## print(df.inversion)

    with(df.inversion, {
        zb <- z3[5]
        ## zm <- z3[3]
        zt <- z3[2]
        xb <- x[5]
        ## xm <- x[3]
        xt <- x[2]
        gb <- gradient[5]
        gt <- gradient[1]  ## note the different index here!

        delta.z <- zt - zb
        delta.x <- xt - xb
        ## A <- 0.5 * (xm - xb) * (zm - zb) + (xm - xb) * (zt - zb) + 0.5 * (xt - xm) * (zt - zm)
        A <- 0.5 * (x[4] - x[5]) * (z3[4] - z3[5]) +
            (x[4] - x[5]) * (z3[3] - z3[4]) + 0.5 * (x[3] - x[4]) * (z3[3] - z3[4]) +
            (x[3] - x[5]) * (z3[2] - z3[3]) + 0.5 * (x[2] - x[3]) * (z3[2] - z3[3]) 
        ## A <- 0.5 * delta.x * delta.z

        ## solve quadratic formula for interface pressure: z_i + 2 p.2 + q = 0 ==> z_i = -p.2 +- sqrt(p.2^2 - q)
        p.2 <- (gt * delta.z - delta.x) / (gb - gt)
        q <- (-gt * delta.z^2 + 2 * delta.z * delta.x - 2 * A) / (gb - gt)

        zi <- -p.2 + c(-1, 1) * sqrt(p.2^2 - q)

        ## sprintf("zb = %e\tzt = %e\txb = %e\txt = %e\tgb = %e\tgt = %e\tzi^2 + %e + %e == 0\tzi = %e or %e\n", zb, zt, xb, xt, gb, gt, 2 * p.2, q, zi[1], zi[2]) %>% cat

        zi.phys <- ifelse(zi <= 0 & zi >= delta.z, zi, NA) %>% ## check within physical bounds (makes sense)
            mean(na.rm = TRUE) ## use the mean if both solutions are physical (shouldn't happen)

        if (debug.plot) {
            print(ggplot(df %>% filter(p > 700e2), aes((z3 - zb), x - xb)) + geom_line() + geom_point() +
                  coord_flip() +
                  scale_x_reverse() +
                  geom_vline(xintercept = c(zb, zt) - zb, lty = "dashed") + geom_hline(yintercept = c(c(xb, xt) - xb, A / delta.z), lty = "dashed") +
                  geom_vline(xintercept = zi.phys, lty = "dotted") +
                  geom_abline(slope = -gb, lty = "dotted") +
                  geom_abline(slope = -gt, intercept = delta.x - delta.z * gt, lty = "dotted") +
                  geom_vline(xintercept = z.pbl - zb, col = "red", alpha = 0.5) ## +
                  ## geom_smooth(data = df %>% filter(p > 700e2, jk < jk.pbl))
                  )
        }
            
        ## print(zi.phys + zb)
        
        return(zi.phys + zb)
    })
}

#' Calculate PBL top height
#'
#' @param df data_frame grouped by all coordinate variables except lev
#' 
#' @export
calculate_h <- function(df, debug.theta = FALSE, debug.q = FALSE) {
    df %>%
        dplyr::mutate(
                   ## h on the vertical grid
                   h = z3[jk == jk.pbl],
                   ## subgrid h calculated from the theta_l profile
                   h_theta = reconstruct_inversion(p, z3, theta_l, debug.theta),
                   ## subgrid h calculated from the qt profile
                   h_q = reconstruct_inversion(p, z3, qt, debug.q),
                   ## same, but applied to pressure
                   p.pbl_theta = reconstruct_inversion_pressure(p, z3, theta_l, debug.theta),
                   p.pbl_q = reconstruct_inversion_pressure(p, z3, qt, debug.q))
}

#' Calculate tendencies
#'
#' @param df data_frame grouped by all coordinate variables except time
#' 
#' @export
calculate_tendencies <- function(df, lead = TRUE) {
    ## assign look-ahead and look-back functions based on whether we
    ## are calculating leading or lagged tendencies
    f.future <- ifelse(lead, dplyr::lead, identity)
    f.past <- ifelse(lead, identity, dplyr::lag)
    
    df %<>% dplyr::mutate(dt = f.future(time) - f.past(time))

    if ("difftime" %in% class(df$dt)) {
        ## let difftime do the conversion to seconds
        df %<>% dplyr::mutate(dt = as.double(dt, units = "secs"))
    } else {
        ## assume [time] == days
        df %<>% dplyr::mutate(dt = 86400 * dt)
    }

    df %>%
        dplyr::mutate(dtheta_l.dt = (f.future(theta_l) - f.past(theta_l)) / dt,
                      dq_t.dt = (f.future(qt) - f.past(qt)) / dt,
                      dq_l.dt = (f.future(ql) - f.past(ql)) / dt,
                      dh.dt = (f.future(h) - f.past(h)) / dt,
                      dh_theta.dt = (f.future(h_theta) - f.past(h_theta)) / dt,
                      dh_q.dt = (f.future(h_q) - f.past(h_q)) / dt,
                      dp.pbl_theta.dt = (f.future(p.pbl_theta) - f.past(p.pbl_theta)) / dt,
                      dp.pbl_q.dt = (f.future(p.pbl_q) - f.past(p.pbl_q)) / dt)
}

#' Transform T tendencies into theta tendencies
#'
#' @export
transform_dT_dtheta <- function(df) {
    df %>%
        dplyr::mutate(dthetacore = dtcore * theta / t,
                      dthetarad = if (exists("dth_rad", where = .)) dth_rad else (qrl + qrs) * theta / t)
}

#' Filter out time steps for which radiative heating was not calculated
#'
#' @export
filter_invalid_qrad <- function(df) {
    if (!exists("qrl", where = df)) {
        df
    } else {
        df %>%
            group_by(time) %>%
            filter(!(all(qrl == 0))) %>%
            ungroup()
    }
}

#' Filter by Medeiros and Stevens (2011) Sc conditions
#'
#' @export
filter_sc <- function(df) {
    df %>%
        filter(lts > 18.55 & omega500 * 864 > 10 & omega700 * 864 > 10)
}

#' Calculate budgets
#'
#' @param df data_frame grouped by all coordinate variables except lev
#' 
#' @export
calculate_budgets <- function(df) {
}

#' Convert from budget units to energy fluxes
#'
#' @export
calculate_fluxes <- function(df) {
    df %>%
        dplyr::mutate(sh = sh.cp * cp,
                      delta.F = delta.F.cp * cp,
                      lh = qflx * Lv)
}

#' Convert from Pa s^-1 to hPa d^-1
#'
#' @export
convert_omega <- function(df) {
    df %>%
        dplyr::mutate(omega700.hPa.d = omega700 * 864,
                      omega500.hPa.d = omega500 * 864,
                      omega.pbl.hPa.d = omega.pbl * 864)
}

#' Convert to conventional LWP and Nd units
#'
#' @export
convert_conventional_units <- function(df) {
    df %>%
        dplyr::mutate(lwp_ic.conventional = lwp_ic * 1e3,
                      cdnc_ic.conventional = cdnc_ic * 1e-6)
}

#' Replace with conventional LWP and Nd units
#'
#' @export
replace_with_conventional_units <- function(df) {
    df %>%
        dplyr::mutate(lwp_ic = lwp_ic * 1e3,
                      cdnc_ic = cdnc_ic * 1e-6,
                      lwp_ic_mean = if (exists("lwp_ic_mean", where = .)) lwp_ic_mean * 1e3 else NA)
}
