x = polygen(QQ)

Lpol = [\
  x^2+1,\
  x^2-x-1,\
  x^3-x^2+2*x+8,\
  x^4 - x^3 - 4*x^2 - 3*x + 79,\
  x^5 - 19*x^3 - 35*x^2 + 18*x - 29,\
  x^4 - 8748*x^3 + 24977727*x^2 + 617645502008739*x + 216058595407965,\
  x^10-3*x^9-35*x^8+120*x^7+242*x^6-1080*x^5+44*x^4+2343*x^3-1631*x^2+111*x+79\
];

def test1(nf,X):
    X *= int((1+10/nf.degree()))
    print(" test 1, X={}".format(X))
    for I in ideals_iterator(nf,1,X):
        lab = ideal_label(I)
        J = ideal_from_label(nf,lab);
        if I != J:
            print("Error in test1: poly {}, {} --> {} --> {}".format(nf.defining_polynomial(),I,lab,J))

def test2(nf,X):
    X *= int((1+10/nf.degree()))
    print(" test 2, X={}".format(X))
    for n in srange(1,X+1):
        nb = len(ideals_of_norm(nf,n))
        for i in srange(1,nb+1):
            lab = "{}.{}".format(n,i)
            if ideal_label(ideal_from_label(nf,lab)) != lab:
                print("Error in test2: poly {} label {}".format(nf.defining_polynomial(),lab))

def test3(nf,X,k):
    k *= int((1+9/nf.degree()))
    print(" test 3, X={}, k={}".format(X,k))
    for t in range(k):
        nb = 0
        while nb==0:
            n = ZZ(randint(1,X))
            nb = len(ideals_of_norm(nf,n))
        i = randint(1,nb)
        lab = "{}.{}".format(n,i)
        J = ideal_from_label(nf,lab)
        lab2 = ideal_label(J)
        if  lab2 != lab:
            print("Error in test3: poly {}, {} --> {} --> {}".format(nf.defining_polynomial(),lab,I,lab2))

def runtests():
    for pol in Lpol:
        print("testing {}".format(pol))
        nf = NumberField(pol,'a')
        print("disc = {}".format(nf.disc()))
        #test1(nf,2000)
        #test2(nf,3000)
        test3(nf,10^20,200)
        test3(nf,10^40,5)

def dump_ideal_list(K, filename, M=10000, k=10):
    out = file(filename, 'w')
    def output_ideal(I,lab=None):
        if lab==None:
            lab = ideal_label(I)
        out.write("{} {}\n".format(lab,I.gens()))

    out.write("# Defining polynomial\n")
    out.write("{}\n".format(K.defining_polynomial()))

    m = 500
    out.write("# Primes of norm up to {}\n".format(m))
    for P in primes_iter(K,maxnorm=500):
        output_ideal(P)

    m = 100
    out.write("# Ideals of norm up to {}\n".format(m))

    for I in ideals_iterator(K,maxnorm=100):
        output_ideal(I)

    out.write("# {} random ideals of norm up to {}\n".format(k,M))

    for t in range(k):
        nb = 0
        while nb==0:
            n = ZZ(randint(1,M))
            II = ideals_of_norm(K,n)
            nb = len(II)
        i = randint(1,nb)
        lab = "{}.{}".format(n,i)
        I = II[i-1]
        output_ideal(I,lab)

def check_ideal(K,L):
    r""" Check the ideal data given by the string L of the form '2.1
(2,a+1)' where K=QQ(a) is a number field.  The ideal generated by the
second part should have label given by the first part.
    """
    #print("Checking L = "+L)
    lab, I = L.split(" ",1) # split on first space
    gens = I[I.find("(")+1:I.find(")")].split(",")
    gens = [g for g in gens if g]
    I = K.ideal([K(c) for c in gens])
    assert ideal_label(I)==lab
    assert ideal_from_label(K,lab)==I

def check_ideal_list(filename):
    Qx = PolynomialRing(QQ,'x')

    for L in file(filename).readlines():
        if L[0]!='#':
            if 'x' in L:
                K = NumberField(Qx(L),'a')
            else:
                check_ideal(K,L)