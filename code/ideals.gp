/* ideals.gp */

\\sort polynomials in Zp[X] of the same degree
\\return 0 if not enough precision
\\o/w return permutation
\\polynomials assumed to be monic and distinct
\\known up to O(p^r)
sortpadic(L,p,r,L2=[[]|i<-[1..#L]]) =
{
 my(perm,k);
 perm = [];
 print(L);
 L = [liftint(Vec(polrecip(P))) | P <- L];
 L = [v[1..#v-1] | v <- L];
 k = -1;
 while(k<r && #perm<#L,
  L2 = [concat(L2[i],L[i]%p) | i <- [1..#L]];
  L \= p;
  perm = vecsort(L2,,1+8);
  k+=1;
  print(k, " ", L2, " ", perm)
 );
 if(k>=r, 0, perm)
}

\\match prime ideals and polynomials
\\ha = h(a), h p-adic factor of minimal polynomial of a
\\return 0 if not enough precision
nfprimematch(nf,ha,p,r,dec=idealprimedec(nf,p)) =
{
 my(cand);
 print("vals: ",[min(nfeltval(nf,ha,pr),(r-1)*pr.e) | pr<-dec]);
 cand = [pr | pr <- dec, nfeltval(nf,ha,pr) >= (r-1)*pr.e];
 if(#cand!=1, 0, cand[1])
}

\\add labels to a sorted list of ideals
\\assumption: for all I in the list,
\\all the ideals J such that N(I)=N(J) and J<I are also in the list,
\\and all ideals in the list are distinct.
\\flag=1: only return the list of labels
addlabels(nf,L,flag=0) =
{
 my(N=0,a,lab=0,Na,L2);
 if(flag,L2 = [1..#L]);
 for(i=1,#L,
   a = L[i];
   Na = idealnorm(nf,a);
   if(Na==N,
     lab += 1,
   \\else
     lab = 1;
     N = Na);
   if(flag,
     L2[i] = [N,lab],
   \\else
     L[i] = [[N,lab],a]);
 );
 if(flag,L2,L)
}

\\sorted prime ideals above p
try_idealprimedecsorted(nf,p,r,dec) =
{
 my(facto,ha,L = [0 | pr <- dec], pp, x = variable(nf.pol),perm);
 facto = factorpadic(nf.pol,p,r);
 facto = facto[,1]~;
 if(#facto!=#dec, print("error: wrong number of primes or factors!", facto,\
   "\n", dec); return(-1));
 for(i=1,#facto,
  ha = subst(lift(facto[i]), x, Mod(x,nf.pol));
  pp = nfprimematch(nf,ha,p,r,dec);
  if(!pp, return(0));
  L[i] = pp
 );
 perm = sortpadic(facto, p, r, [[pp.f,pp.e] | pp <- L]);
 if(perm,[dec[perm[i]] | i<-[1..#dec]],0)
}
idealprimedecsorted(nf,p) =
{
 my(dec=idealprimedec(nf,p),r=10,res=0);
 while(!res,
  res = try_idealprimedecsorted(nf,p,r,dec);
  r *= 3
 );
 res
}

\\sorted prime ideals up to norm X
nfprimesupto(nf,x) =
{
  my(Lp,Llab,perm);
  Lp = primes([0,x]);
  Lp = [idealprimedecsorted(nf,p) | p<-Lp];
  Lp = [[pr | pr<-dec, idealnorm(nf,pr)<=x] | dec<-Lp];
  Llab = [addlabels(nf,dec) | dec<-Lp];
  Lp = concat(Lp);
  Llab = concat(Llab);
  perm = vecsort(Llab,,1);
  [Lp[perm[i]] | i <- [1..#perm]]
}

\\nextprimeideal

\\list of solutions x_i>=0 to sum_i a_i x_i = k (a_i>0, k>=0)
intlinsols(a,k) =
{
  my(n = #a,L = [], L2);
  if(n==1,
    if(k%a[1], return([]), return([k\a[1]]))
  );
  for(xn=0,k\a[n],
    L2 = intlinsols(a[1..n-1],k-xn*a[n]);
    L = concat(L, [concat(v,[xn]) | v <- L2])
  );
  L
}

weightrev(L) =
{
  [concat([vecsum(v)],-v) | v <- L];
}
maxes(L) =
{
  my(M = L[1]);
  for(i=2,#L,
    for(j=1,#M,
      if(L[i][j]>M[j],M[j]=L[i][j])
    )
  );
  M
}
idealspowers(nf,L,M) =
{
  my(pow=L, a, pow2);
  for(i=1,#L,
    a = L[i];
    pow2 = [1..M[i]+1];
    for(j=1,M[i],
      pow2[j+1] = idealmul(nf,pow2[j],a)
    );
    pow[i] = pow2;
  );
  pow
}
idealprod(nf,L) =
{
  my(res=1);
  for(i=1,#L,res = idealmul(nf,res,L[i]));
  res
}
idealmultlist(nf,pows,L) =
{
  my(L2 = [1..#L],expo);
  for(i=1,#L,
    expo = L[i];
    L2[i] = idealprod(nf,[pows[j][expo[j]+1] | j <- [1..#expo]]);
  );
  L2
}

\\sorted list of ideals of a given prime power norm p^k
idealsprimepowernorm(nf,p,k,dec = idealprimedecsorted(nf,p)) =
{
  my(L,a = [pp.f | pp <- dec],M,pow,keys,L2,perm);
  L = intlinsols(a,k);
  if(!#L,return([]));
  keys = weightrev(L);
  M = maxes(L);
  pow = idealspowers(nf,dec,M);
  L2 = idealmultlist(nf,pow,L);
  perm = vecsort(keys,,1);
  [L2[perm[i]] | i <- [1..#perm]]
}

\\key function for prime power norm ideals

\\sorted list of prime power norm ideals up to norm X

lexallprods(nf,LL) =
{
  my(L,k=#LL);
  if(k==0, return([1]));
  L = lexallprods(nf,LL[2..k]);
  L = [[idealmul(nf,a,b) | b <- L] | a <- LL[1]];
  concat(L)
}

\\sorted list of ideals of a given norm
\\N can be a factorisation matrix
idealsofnorm(nf,N) =
{
  my(k, primepow, facto=N);
  if(type(facto)!="t_MAT", facto=factor(N));
  k = #facto[,1];
  primepow = [idealsprimepowernorm(nf,facto[i,1],facto[i,2]) | i<-[1..k]];
  lexallprods(nf,primepow)
}

\\cmp function for ideals

\\sorted ideals up to norm X

\\combinatorics functions
\\...

\\ideal -> label

\\label -> ideal

\\nextideal
