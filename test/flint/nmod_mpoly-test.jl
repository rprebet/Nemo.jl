@testset "zzModMPolyRingElem.constructors" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 0:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    SS, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    @test S === SS

    SSS, varlist = polynomial_ring(R, var_names, internal_ordering = ord, cached = false)
    SSSS, varlist = polynomial_ring(R, var_names, internal_ordering = ord, cached = false)

    @test !(SSS === SSSS)

    if num_vars > 0
      @test string(varlist[1]) == var_names[1]
    end
    @test nvars(S) == num_vars
    @test modulus(S) == modulus(R)
    if num_vars > 0
      @test modulus(varlist[1]) == modulus(R)
    end

    @test elem_type(S) == zzModMPolyRingElem
    @test elem_type(zzModMPolyRing) == zzModMPolyRingElem
    @test parent_type(zzModMPolyRingElem) == zzModMPolyRing

    @test Nemo.promote_rule(elem_type(S), ZZRingElem) == elem_type(S)

    @test S isa zzModMPolyRing

    @test isa(symbols(S), Vector{Symbol})

    for j = 1:num_vars
      @test isa(varlist[j], zzModMPolyRingElem)
      @test isa(gens(S)[j], zzModMPolyRingElem)
    end

    f =  rand(S, 0:5, 0:100)

    @test isa(f, zzModMPolyRingElem)

    @test isa(S(2), zzModMPolyRingElem)

    @test isa(S(R(2)), zzModMPolyRingElem)

    @test isa(S(f), zzModMPolyRingElem)

    V = [(rand(-100:100)) for i in 1:5]

    W0 = [ UInt[rand(0:100) for i in 1:num_vars] for j in 1:5]

    f = S(map(v -> R.(v), V), W0)

    @test isa(f, zzModMPolyRingElem)

    # Test the BuildCtx

    for RR in [Int, ZZ, R]
      bctx = MPolyBuildCtx(S)
      @test (@which push_term!(bctx, RR(1), zeros(Int, num_vars))).module === Nemo
      for (v, w0) in zip(V, W0)
        push_term!(bctx, RR(v), Int.(w0))
      end
      ff = finish(bctx)
      @test isa(ff, zzModMPolyRingElem)
      @test f == ff
    end

    bctx = MPolyBuildCtx(S)
    @test_throws ErrorException push_term!(bctx, one(R), zeros(Int, num_vars + 1))
    if num_vars > 0
      @test_throws ErrorException push_term!(bctx, one(R), zeros(Int, num_vars - 1))
    end
    @test (@which finish(bctx)).module === Nemo

    for i in 1:num_vars
      f = gen(S, i)
      @test is_gen(f, i)
      @test is_gen(f)
      @test !is_gen(f + 1, i)
      @test !is_gen(f + 1)
    end
  end

  RR, = residue_ring(ZZ, 29)
  S, (x, y) = polynomial_ring(R, ["x", "y"])
  M = MPolyBuildCtx(S)
  @test_throws ErrorException push_term!(M, one(RR), zeros(Int, 2))
end

@testset "zzModMPolyRingElem.krull_dim" begin
  R, = residue_ring(ZZ, 1)
  S, = polynomial_ring(R, ["x", "y"])
  @test krull_dim(S) == -inf

  R, = residue_ring(ZZ, 2)
  S, = polynomial_ring(R, ["x", "y"])
  @test krull_dim(S) == 2

  R, = residue_ring(ZZ, 4)
  S, = polynomial_ring(R, ["x", "y"])
  @test krull_dim(S) == 2
end

@testset "zzModMPolyRingElem.printing" begin
  S, (x, y) = polynomial_ring(residue_ring(ZZ, 23)[1], ["x", "y"])

  @test !occursin(r"{", string(S))

  @test string(zero(S)) == "0"
  @test string(one(S)) == "1"
  @test string(x) == "x"
  @test string(y) == "y"

  a = ZZRingElem(3)^100
  b = ZZRingElem(2)^100
  @test string(x^a + y^b) == "x^$a + y^$b"
end

@testset "zzModMPolyRingElem.hash" begin
  S, (x, y) = polynomial_ring(residue_ring(ZZ, 23)[1], ["x", "y"])

  p = y^ZZRingElem(2)^100

  @test hash(x) == hash((x + y) - y)
  @test hash(x) == hash((x + p) - p)
end

@testset "zzModMPolyRingElem.manipulation" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)
    g = gens(S)

    @test characteristic(S) == 23

    @test S(2) == 2
    @test S(2) == R(2)
    @test S(2) == UInt(2)
    @test S(BigInt(2)) == UInt(2)

    @test !is_gen(S(1))

    for i = 1:num_vars
      @test is_gen(varlist[i])
      @test is_gen(g[i])
      @test !is_gen(g[i] + 1)
    end

    f = rand(S, 0:5, 0:100)

    @test f == deepcopy(f)

    if length(f) > 0
      i = rand(1:(length(f)))
      @test isa(coeff(f, i), elem_type(R))
    end

    r = S()
    m = S()
    for i = 1:length(f)
      m = monomial!(m, f, i)
      @test m == monomial(f, i)
      @test term(f, i) == coeff(f, i)*monomial(f, i)
      r += coeff(f, i)*monomial(f, i)
    end
    @test f == r

    for i = 1:length(f)
      i1 = rand(1:length(f))
      i2 = rand(1:length(f))
      @test (i1 < i2) == (monomial(f, i1) > monomial(f, i2))
      @test (i1 > i2) == (monomial(f, i1) < monomial(f, i2))
      @test (i1 == i2) == (monomial(f, i1) == monomial(f, i2))
    end

    f = rand(S, 1:5, 0:100)

    if length(f) > 0
      @test f == sum((coeff(f, i) * S([R(1)], [Nemo.exponent_vector(f, i)])  for i in 1:length(f)))
      @test f == sum((coeff(f, i) * S([R(1)], [Nemo.exponent_vector_ui(f, i)])  for i in 1:length(f)))
      @test f == sum((coeff(f, i) * S([R(1)], [Nemo.exponent_vector_fmpz(f, i)])  for i in 1:length(f)))
    end

    deg = is_degree(internal_ordering(S))
    rev = is_reverse(internal_ordering(S))

    @test ord == internal_ordering(S)

    @test isone(one(S))

    @test iszero(zero(S))

    @test is_constant(S(rand(-100:100)))
    @test is_constant(S(zero(S)))

    g = S()
    while g == 0
      g = rand(S, 1:1, 0:100)
    end
    h = S()
    while h == 0
      h = rand(S, 1:1, 0:100)
    end
    h = setcoeff!(h, 1, 1)
    h2 = S()
    while length(h2) < 2
      h2 = rand(S, 2:2, 1:100)
    end

    @test is_term(h)
    @test !is_term(h2 + 1 + gen(S, 1))

    @test is_unit(S(1))
    @test !is_unit(gen(S, 1))

    @test is_monomial(gen(S, 1)*gen(S, num_vars))
    @test !is_monomial(2*gen(S, 1)*gen(S, num_vars))

    monomialexp = unique([UInt[rand(0:10) for j in 1:num_vars] for k in 1:10])
    coeffs = [rand(R) for k in 1:length(monomialexp)]
    for i = 1:length(coeffs)
      while coeffs[i] == 0
        coeffs[i] = rand(R)
      end
    end
    h = S(coeffs, monomialexp)
    @test length(h) == length(monomialexp)
    for k in 1:length(h)
      @test coeff(h, S([R(1)], [monomialexp[k]])) == coeffs[k]
    end

    max_degs = max.(monomialexp...)
    for k = 1:num_vars
      @test (degree(h, k) == max_degs[k]) || (h == 0 && degree(h, k) == -1)
      @test degrees(h)[k] == degree(h, k)
      @test degrees_fmpz(h)[k] == degree(h, k)
      @test degrees_fmpz(h)[k] == degree_fmpz(h, k)
    end

    @test degrees_fit_int(h)

    @test (total_degree(h) == max(sum.(monomialexp)...)) || (h == 0 && total_degree(h) == -1)
    @test (total_degree_fmpz(h) == max(sum.(monomialexp)...)) || (h == 0 && total_degree(h) == -1)
    @test total_degree_fits_int(h)
  end

  S, (x, y) = polynomial_ring(R, ["x", "y"])

  @test trailing_coefficient(3x^2*y^2 + 2x*y + 5x + y + 7) == 7
  @test trailing_coefficient(3x^2*y^2 + 2x*y + 5x) == 5
  @test trailing_coefficient(x) == 1
  @test trailing_coefficient(S(2)) == 2
  @test trailing_coefficient(S()) == 0

  f = x^(ZZ(2)^100) * y^100
  @test_throws InexactError degree(f, 1)
  @test degree(f, 2) == 100
  @test_throws OverflowError degrees(f)
  @test_throws OverflowError total_degree(f)
end

@testset "zzModMPolyRingElem.multivariate_coeff" begin
  R, = residue_ring(ZZ, 23)

  for ord in Nemo.flint_orderings
    S, (x, y, z) = polynomial_ring(R, ["x", "y", "z"]; internal_ordering=ord)

    f = 15*x^5*y^3*z^5+9*x^5*y^2*z^3+15*x^4*y^5*z^4+13*x^4*y^3*z^2+8*x^3*y^2*z+13*x*y^3*z^4+19*x*y+13*x*z^2+8*y^2*z^5+14*y^2*z^3

    @test coeff(f, [1], [1]) == 13*y^3*z^4+19*y+13*z^2
    @test coeff(f, [2, 3], [3, 2]) == 13*x^4
    @test coeff(f, [1, 3], [4, 5]) == 0

    @test coeff(f, [x], [1]) == 13*y^3*z^4+19*y+13*z^2
    @test coeff(f, [y, z], [3, 2]) == 13*x^4
    @test coeff(f, [x, z], [4, 5]) == 0
  end
end

@testset "zzModMPolyRingElem.unary_ops" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:5, 0:100)

      @test f == -(-f)
    end
  end
end

@testset "zzModMPolyRingElem.binary_ops" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:5, 0:100)
      g = rand(S, 0:5, 0:100)
      h = rand(S, 0:5, 0:100)

      @test f + g == g + f
      @test f - g == -(g - f)
      @test f*g == g*f
      @test f*g + f*h == f*(g + h)
      @test f*g - f*h == f*(g - h)
    end
  end
end

@testset "zzModMPolyRingElem.adhoc_binary" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:100
      f = rand(S, 0:5, 0:100)

      d1 = rand(-20:20)
      d2 = rand(-20:20)
      g1 = rand(R, -10:10)
      g2 = rand(R, -10:10)

      @test f*d1 + f*d2 == (d1 + d2)*f
      @test f*BigInt(d1) + f*BigInt(d2) == (BigInt(d1) + BigInt(d2))*f
      @test f*g1 + f*g2 == (g1 + g2)*f

      @test f + d1 + d2 == d1 + d2 + f
      @test f + BigInt(d1) + BigInt(d2) == BigInt(d1) + BigInt(d2) + f
      @test f + g1 + g2 == g1 + g2 + f

      @test f - d1 - d2 == -((d1 + d2) - f)
      @test f - BigInt(d1) - BigInt(d2) == -((BigInt(d1) + BigInt(d2)) - f)
      @test f - g1 - g2 == -((g1 + g2) - f)

      @test f + d1 - d1 == f
      @test f + BigInt(d1) - BigInt(d1) == f
      @test f + g1 - g1 == f
    end
  end
end

@testset "zzModMPolyRingElem.adhoc_comparison" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:100
      d = rand(-100:100)

      @test S(d) == d
      @test d == S(d)
      @test S(ZZRingElem(d)) == ZZRingElem(d)
      @test ZZRingElem(d) == S(ZZRingElem(d))
      @test S(d) == BigInt(d)
      @test BigInt(d) == S(d)
    end
  end
end

@testset "zzModMPolyRingElem.powering" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:5, 0:100)

      expn = rand(0:10)

      r = S(1)
      for i = 1:expn
        r *= f
      end

      @test (f == 0 && expn == 0 && f^expn == 0) || f^expn == r

      @test_throws DomainError f^-1
      @test_throws DomainError f^ZZRingElem(-1)
    end
  end
end

@testset "zzModMPolyRingElem.divides" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:5, 0:100)
      g = rand(S, 0:5, 0:100)

      @test iszero(f) || !divides(f, S(0))[1]
      @test divexact(2*f, 2) == f
      @test divexact(2*f, R(2)) == f
      @test divexact(2*f, ZZRingElem(2)) == f

      p = f*g

      flag, q = divides(p, f)

      if flag
        @test q * f == p
      end

      if !iszero(f)
        q = divexact(p, f)
        @test q == g
      end
    end
  end
end

@testset "zzModMPolyRingElem.euclidean_division" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = S(0)
      while iszero(f)
        f = rand(S, 0:5, 0:100)
      end
      g = rand(S, 0:5, 0:100)

      p = f*g

      q1, r = divrem(p, f)
      q2 = div(p, f)

      @test q1 == g
      @test q2 == g
      @test f*q1 + r == p

      q3, r3 = divrem(g, f)
      q4 = div(g, f)
      flag, q5 = divides(g, f)

      @test q3*f + r3 == g
      @test q3 == q4
      @test (r3 == 0 && flag == true && q5 == q3) || (r3 != 0 && flag == false)
    end
  end
end

@testset "zzModMPolyRingElem.ideal_reduction" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = S(0)
      while iszero(f)
        f = rand(S, 0:5, 0:100)
      end
      g = rand(S, 0:5, 0:100)

      p = f*g

      q1, r = divrem(p, [f])

      @test q1[1] == g
      @test r == 0
    end

    for iter = 1:10
      num = rand(1:5)

      V = Vector{elem_type(S)}(undef, num)

      for i = 1:num
        V[i] = S(0)
        while iszero(V[i])
          V[i] = rand(S, 0:5, 0:100)
        end
      end
      g = rand(S, 0:5, 0:100)

      q, r = divrem(g, V)

      p = r
      for i = 1:num
        p += q[i]*V[i]
      end

      @test p == g
    end
  end
end

@testset "zzModMPolyRingElem.gcd" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:4
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:4, 0:5)
      g = rand(S, 0:4, 0:5)
      h = rand(S, 0:4, 0:5)

      g1 = gcd(f, g)
      g2 = gcd(f*h, g*h)

      if !iszero(h) && !iszero(g1)
        b, q = divides(g2, g1 * h)
        @test b
        @test is_constant(q)
      end
    end
  end
end

@testset "zzModMPolyRingElem.factor" begin
  R, = residue_ring(ZZ, 23)
  R, (x, y, z) = polynomial_ring(R, ["x", "y", "z"])

  @test_throws ArgumentError factor(R(0))
  @test_throws ArgumentError factor_squarefree(R(0))

  function check_factor(a, esum)
    f = factor(a)
    @test a == unit(f) * prod([p^e for (p, e) in f])
    @test esum == sum(e for (p, e) in f)

    f = factor_squarefree(a)
    @test a == unit(f) * prod([p^e for (p, e) in f])
  end

  check_factor(3*x^23+2*y^23+z^23, 23)
  check_factor(x^99-y^99*z^33, 22)
end

@testset "zzModMPolyRingElem.sqrt" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:4
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:10
      f = rand(S, 0:4, 0:5, -10:10)

      g = sqrt(f^2)

      @test g^2 == f^2
      @test is_square(f^2)

      if f != 0
        x = varlist[rand(1:num_vars)]
        @test_throws ErrorException sqrt(f^2*(x^2 - x))
        @test !is_square(f^2*(x^2 - x))
      end
    end
  end
end

@testset "zzModMPolyRingElem.evaluation" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:100
      f = rand(S, 0:5, 0:100)
      g = rand(S, 0:5, 0:100)

      V1 = [rand(-10:10) for i in 1:num_vars]

      r1 = evaluate(f, V1)
      r2 = evaluate(g, V1)
      r3 = evaluate(f + g, V1)

      @test r3 == r1 + r2
      @test (f + g)(V1...) == f(V1...) + g(V1...)

      V2 = [BigInt(rand(-10:10)) for i in 1:num_vars]

      r1 = evaluate(f, V2)
      r2 = evaluate(g, V2)
      r3 = evaluate(f + g, V2)

      @test r3 == r1 + r2
      @test (f + g)(V2...) == f(V2...) + g(V2...)

      V3 = [R(rand(-10:10)) for i in 1:num_vars]

      r1 = evaluate(f, V3)
      r2 = evaluate(g, V3)
      r3 = evaluate(f + g, V3)

      @test r3 == r1 + r2
      @test (f + g)(V3...) == f(V3...) + g(V3...)
    end
  end

  # Individual tests

  S, (x, y) = polynomial_ring(R, ["x", "y"])
  @test_throws ErrorException evaluate(x, [x])
  @test_throws ErrorException evaluate(x, [x, x, x])

  @test (@which evaluate(f, [R(1), R(1)])).module === Nemo

  f = x + y
  g = x - y
  r1 = @inferred evaluate(f, [x + y, x^2 + y^2])
  r2 = evaluate(g, [x + y, x^2 + y^2])
  r3 = evaluate(f + g, [x + y, x^2 + y^2])
  @test r3 == r1 + r2

  @test (@which evaluate(f, [x])).module === Nemo

  SS, (xx, yy, zz) = polynomial_ring(R, ["xx", "yy", "zz"])
  r1 = @inferred evaluate(f, [xx + yy, yy + zz])
  r2 = evaluate(g, [xx + yy, yy + zz])
  r3 = evaluate(f + g, [xx + yy, yy + zz])
  @test r3 == r1 + r2

  SS, z = polynomial_ring(R, "z")
  @test_throws ErrorException evaluate(x, [z])
  @test_throws ErrorException evaluate(x, [z, z, z])
  w = [z, (z + 1)^2]
  r1 = @inferred evaluate(f, w)
  r2 = evaluate(g, w)
  r3 = evaluate(f + g, w)
  @test r3 == r1 + r2
  @test (@which evaluate(f, w)).module === Nemo

  T = matrix_ring(R, 2)

  f = x^2*y^2+2*x+1

  M1 = T([1 2; 3 4])
  M2 = T([1 1; 2 4])

  @test f(M1, M2) == T([9 12; 18 20])

  @test evaluate(f, [ZZRingElem(20), ZZRingElem(30)]) == R(20^2*30^2+2*20+1)
  @test evaluate(f, [UInt(20), UInt(30)]) == R(20^2*30^2+2*20+1)
end

@testset "zzModMPolyRingElem.valuation" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for iter = 1:100
      f = S()
      g = S()
      while f == 0 || g == 0 || is_constant(g)
        f = rand(S, 0:5, 0:100)
        g = rand(S, 0:5, 0:100)
      end

      d1 = valuation(f, g)

      expn = rand(1:5)

      d2 = valuation(f*g^expn, g)

      @test d2 == d1 + expn

      d3, q3 = remove(f, g)

      @test d3 == d1
      @test f == q3*g^d3

      d4, q4 = remove(q3*g^expn, g)

      @test d4 == expn
      @test q4 == q3
    end
  end
end

@testset "zzModMPolyRingElem.derivative" begin
  R, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    S, varlist = polynomial_ring(R, var_names, internal_ordering = ord)

    for j in 1:100
      f = rand(S, 0:5, 0:100)
      g = rand(S, 0:5, 0:100)

      for i in 1:num_vars
        @test derivative(f*g, i) == f*derivative(g, i) + derivative(f, i)*g
      end
    end
  end
end

@testset "zzModMPolyRingElem.unsafe" begin
  R23, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    R, vars_R = polynomial_ring(R23, var_names; internal_ordering=ord)

    for iter in 1:10
      f = R()
      while f == 0
        f = rand(R, 5:10, 1:10)
      end

      lenf = length(f)
      f = setcoeff!(f, rand(1:lenf), 0)
      f = combine_like_terms!(f)

      @test length(f) == lenf - 1

      while length(f) < 2
        f = rand(R, 5:10, 1:10)
      end

      lenf = length(f)
      nrand = rand(1:lenf - 1)
      v = exponent_vector(f, nrand)
      f = set_exponent_vector!(f, nrand + 1, v)
      terms_cancel = coeff(f, nrand) == -coeff(f, nrand + 1)
      f = combine_like_terms!(f)
      @test length(f) == lenf - 1 - terms_cancel
    end
  end

  S, (x, y) = polynomial_ring(R23, ["x", "y"])

  f = one(S)
  zero!(f)
  setcoeff!(f, 1, 1)
  set_exponent_vector!(f, 1, [ZZRingElem(1), ZZRingElem(0)])
  set_exponent_vector!(f, 2, [UInt(0), UInt(1)])
  setcoeff!(f, 2, 2)
  setcoeff!(f, 3, 3)
  set_exponent_vector!(f, 3, [UInt(2), UInt(0)])
  set_exponent_vector!(f, 4, [ZZRingElem(0), ZZRingElem(2)])
  setcoeff!(f, 4, 4)
  sort_terms!(f)
  @test f == 1*x+2*y+3*x^2+4*y^2

  f = add!(f, y^2, x*y)
  @test f == y^2 + x*y
  f = add!(f, x^2)
  @test f == y^2 + x*y + x^2
  f = mul!(f, f, x)
  @test f == (y^2 + x*y + x^2)*x
end

@testset "zzModMPolyRingElem.exponents" begin
  R23, = residue_ring(ZZ, 23)

  for num_vars = 1:10
    var_names = ["x$j" for j in 1:num_vars]
    ord = rand_ordering()

    R, vars_R = polynomial_ring(R23, var_names; internal_ordering=ord)

    for iter in 1:10
      f = R()
      while f == 0
        f = rand(R, 5:10, 1:10)
      end

      nrand = rand(1:length(f))
      v = exponent_vector(f, nrand)
      c = coeff(f, v)

      @test c == coeff(f, nrand)
      for ind = 1:length(v)
        @test v[ind] == exponent(f, nrand, ind)
      end
    end

    for iter in 1:10
      num_vars = nvars(R)

      f = R()
      rand_len = rand(0:10)

      for i = 1:rand_len
        f = set_exponent_vector!(f, i, [rand(0:10) for j in 1:num_vars])
        f = setcoeff!(f, i, rand(ZZ, -10:10))
      end

      f = sort_terms!(f)
      f = combine_like_terms!(f)

      for i = 1:length(f) - 1
        @test exponent_vector_ui(f, i) != exponent_vector_ui(f, i + 1)
        @test exponent_vector(f, i) != exponent_vector(f, i + 1)
        @test coeff(f, i) != 0
        @test coeff(f, i + 1) != 0
      end
    end

    f = rand(vars_R)^(ZZRingElem(typemax(UInt)) + 1)
    @test !exponent_vector_fits_int(f, 1)
    @test !exponent_vector_fits_ui(f, 1)
    @test_throws DomainError exponent_vector(f, 1)
  end

  S, (x, y) = polynomial_ring(R23, ["x", "y"])

  f = 1+2*x+3*y^2
  @test coeff(f, [UInt(1), UInt(0)]) == 2
  @test coeff(f, [UInt(1), UInt(1)]) == 0

  setcoeff!(f, [2,3], 1)
  @test f == 1+2*x+3*y^2+x^2*y^3

  setcoeff!(f,[UInt(0), UInt(2)], R23(0))
  @test f == 1+2*x+x^2*y^3

  m = [[0,0], [1,0], [0,1]]
  @test S([R23(0), R23(1), R23(2)], m) == 1*x+2*y

  m = [[ZZRingElem(0),ZZRingElem(0)], [ZZRingElem(1),ZZRingElem(0)], [ZZRingElem(0),ZZRingElem(1)]]
  @test S([R23(0), R23(1), R23(2)], m) == 1*x+2*y

  m = [[BigInt(0),BigInt(0)], [BigInt(1),BigInt(0)], [BigInt(0),BigInt(1)]]
  @test S([BigInt(0), BigInt(1), BigInt(2)], m) == 1*x+2*y
end
