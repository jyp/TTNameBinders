{-# OPTIONS  --type-in-type #-}
module NamesRel where

open import Type hiding (★_)
open import Function.NP
open import Data.Sum.NP renaming (map to map-⊎; ⟦map⟧ to ⟦map-⊎⟧)
open import Relation.Binary.Logical hiding (⟦★⟧) renaming (⟦★₀⟧ to ⟦★⟧)
open import Level
import Relation.Binary.PropositionalEquality as ≡
open ≡ using (_≡_)
open import Relation.Binary
open import Data.Product.NP hiding (map)
--open import Names

module V1 where

    data Term (V : ★) : ★ where
      var : V → Term V
      abs : (∀ {W} → W → Term (V ⊎ W)) → Term V
      app : Term V → Term V → Term V
 
    map : ∀{U V} → (U → V) → Term U → Term V
    map f (abs t)   = abs (λ x → map (map-⊎ f id) (t x))
    map f (var x)   = var (f x)
    map f (app t u) = app (map f t) (map f u)

    IdTerm = ∀ {V} → Term V → Term V

    TwoTerm = ∀ {V} → Term V → Term V → Term V

    data Term⟧ {V₁ V₂} (Vᵣ : ⟦★⟧ V₁ V₂) : Term V₁ → Term V₂ → ★ where
      var : (Vᵣ ⟦→⟧ Term⟧ Vᵣ) var var
      abs : ((∀⟨ W ∶ ★ ⟩→⟧ W →⟧ Term⟧ (Vᵣ ⟦⊎⟧ _≡_)) ⟦→⟧ Term⟧ Vᵣ) abs abs
      app : (Term⟧ Vᵣ ⟦→⟧ Term⟧ Vᵣ ⟦→⟧ Term⟧ Vᵣ) app app

    IdTerm⟧ : ⟦★⟧ IdTerm IdTerm
    IdTerm⟧ = ∀⟨ Vᵣ ∶ ⟦★⟧ ⟩⟦→⟧ Term⟧ Vᵣ ⟦→⟧ Term⟧ Vᵣ

    TwoTerm⟧ : ⟦★⟧ TwoTerm TwoTerm
    TwoTerm⟧ = ∀⟨ Vᵣ ∶ ⟦★⟧ ⟩⟦→⟧ Term⟧ Vᵣ ⟦→⟧ Term⟧ Vᵣ ⟦→⟧ Term⟧ Vᵣ

    module Term⟧-props where

      refl : ∀ {V} {Vᵣ : ⟦★⟧ V V} → Reflexive Vᵣ → Reflexive (Term⟧ Vᵣ)
      refl θ {var x}   = var θ
      refl θ {abs f}   = abs (λ x → refl (⟦⊎⟧-refl _ θ _ ≡.refl) {f x})
      refl θ {app _ _} = app (refl θ) (refl θ)

      sym : ∀ {V₁ V₂ : ★} {Vᵣ : V₁ → V₂ → ★} {Wᵣ : V₂ → V₁ → ★}
            → Sym Vᵣ Wᵣ
            → Sym (Term⟧ Vᵣ) (Term⟧ Wᵣ)
      sym θ (var xᵣ)    = var (θ xᵣ)
      sym θ (abs fᵣ)    = abs (λ x → sym (⟦⊎⟧-sym θ ≡.sym) (fᵣ x))
      sym θ (app tᵣ uᵣ) = app (sym θ tᵣ) (sym θ uᵣ)

      symmetric : ∀ {V : ★} {Vᵣ : V → V → ★} → Symmetric Vᵣ → Symmetric (Term⟧ Vᵣ)
      symmetric = sym

      trans : ∀ {A₁ A₂ A₃ : ★} {A₁₂ : ⟦★⟧ A₁ A₂} {A₂₃ : ⟦★⟧ A₂ A₃} {A₁₃ : ⟦★⟧ A₁ A₃}
              → Trans A₁₂ A₂₃ A₁₃
              → Trans (Term⟧ A₁₂) (Term⟧ A₂₃) (Term⟧ A₁₃)
      trans A-trans (var xᵣ)   (var yᵣ)   = var (A-trans xᵣ yᵣ)
      trans A-trans (abs fᵣ)   (abs gᵣ)   = abs (λ x → trans (⟦⊎⟧-trans A-trans ≡.trans) (fᵣ x) (gᵣ x))
      trans A-trans (app p p₁) (app q q₁) = app (trans A-trans p q) (trans A-trans p₁ q₁)

      transitive : ∀ {A : ★} {Aᵣ : ⟦★⟧ A A} → Transitive Aᵣ → Transitive (Term⟧ Aᵣ)
      transitive = trans

      cong-fu :   (f  : ∀ {A} → Term A → Term A)
                  (fᵣ : IdTerm⟧ f f)
                → ∀ {A₁ A₂} (Aᵣ : ⟦★⟧ A₁ A₂) {t u} → Term⟧ Aᵣ t u → Term⟧ Aᵣ (f t) (f u)
      cong-fu _ = id

      cong₂-fu : (f  : TwoTerm)
                 (fᵣ : TwoTerm⟧ f f)
                → ∀ {A₁ A₂} (Aᵣ : ⟦★⟧ A₁ A₂) {t u t' u'} → Term⟧ Aᵣ t u → Term⟧ Aᵣ t' u' → Term⟧ Aᵣ (f t t') (f u u')
      cong₂-fu _ fᵣ Aᵣ tᵣ = fᵣ Aᵣ tᵣ

      cong₂-fu' : ∀ (TwoTerm⟧-refl : Reflexive TwoTerm⟧)
                    (f : TwoTerm) {A₁ A₂} (Aᵣ : ⟦★⟧ A₁ A₂) {t u t' u'} → Term⟧ Aᵣ t u → Term⟧ Aᵣ t' u' → Term⟧ Aᵣ (f t t') (f u u')
      cong₂-fu' refl f Aᵣ tᵣ = refl {f} Aᵣ tᵣ

      private
        cong₂-fu-app = cong₂-fu app (λ _ → app)

    data ⟦Term⟧ {V₁ V₂} (Vᵣ : ⟦★⟧ V₁ V₂) : Term V₁ → Term V₂ → ★ where
      var : (Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) var var
      abs : ((∀⟨ Wᵣ ∶ ⟦★⟧ ⟩⟦→⟧ Wᵣ ⟦→⟧ ⟦Term⟧ (Vᵣ ⟦⊎⟧ Wᵣ)) ⟦→⟧ ⟦Term⟧ Vᵣ) abs abs
      app : (⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) app app

    mapR : (∀⟨ UR ∶ ⟦★⟧ ⟩⟦→⟧ ∀⟨ VR ∶ ⟦★⟧ ⟩⟦→⟧  (UR ⟦→⟧ VR) ⟦→⟧ ⟦Term⟧ UR ⟦→⟧ ⟦Term⟧ VR) map map
    mapR UR VR fr (var xᵣ) = var (fr xᵣ)
    mapR UR VR fr (abs xᵣ) = abs (λ {W1} {W2} Wᵣ {w1} {w2} wᵣ → mapR (UR ⟦⊎⟧ Wᵣ) (VR ⟦⊎⟧ Wᵣ) (⟦map-⊎⟧ _ _ _ _ fr id) (xᵣ Wᵣ wᵣ))
    mapR UR VR fr (app tr tr₁) = app (mapR UR VR fr tr) (mapR UR VR fr tr₁)

    ⟦IdTerm⟧ : ⟦★⟧ IdTerm IdTerm
    ⟦IdTerm⟧ = ∀⟨ Vᵣ ∶ ⟦★⟧ ⟩⟦→⟧ ⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ

    
    ⟦Term⟧-refl : ∀ {V} → (t : Term V) → ⟦Term⟧ _≡_ t t
    ⟦Term⟧-refl (var x) = var ≡.refl
    ⟦Term⟧-refl (abs x) = abs (λ {W1} {W2} Wᵣ {w1} {w2} wᵣ → {!!})
    ⟦Term⟧-refl (app t t₁) = app (⟦Term⟧-refl t) (⟦Term⟧-refl t₁)

    postulate ⟦Term⟧-trans : ∀ {V} → Transitive (⟦Term⟧ {V} _≡_)
    


    -- data RelOf {A B : ★} (f : A → B) : A → B → ★ where
    --  relOf : ∀ {x} → RelOf f x (f x)

    RelOf : ∀ {A B : ★} (f : A → B) → A → B → ★
    RelOf f x y = f x ≡ y

    proof : ∀ {V W} (φ : V → W) t → ⟦Term⟧ (RelOf φ) (map id t) (map φ t)
    proof φ t = mapR (λ z z1 → z ≡ id z1) (RelOf φ) {id} {φ} (≡.cong φ)  {t} {t} (⟦Term⟧-refl t)

    proof' : ∀ {V W} (φ : V → W) → (t : Term V) → ⟦Term⟧ (RelOf φ) t (map φ t)
    proof' = {!proof!}
 
    postulate extensionality' : ∀ {B : Set → Set} {f g : {W : Set} → W → B W} → (∀ W → (w : W) → f w ≡ g w) → (\{x} → f {x}) ≡ \{x} → g {x}

    yak1 : ∀{V W U : Set} (φ : V → W) (R : REL V W zero) → (R ⇒ RelOf φ) → (R ⟦⊎⟧ (_≡_ {zero} {U})) ⇒ RelOf [ (λ x₁ → inj₁ (φ x₁)) , (λ x₁ → inj₂ x₁) ] 
    yak1 φ R q (inj₁ xᵣ) = ≡.cong inj₁ (q xᵣ)
    yak1 φ R q (inj₂ xᵣ) = ≡.cong inj₂ xᵣ

    inverseproof : ∀ {V W} (φ : V → W) {t1 t2} (R : REL V W _) → (R ⇒ RelOf φ) → ⟦Term⟧ R t1 t2 → (map φ t1) ≡ t2
    inverseproof φ R q (var xᵣ) = ≡.cong var (q xᵣ)
    inverseproof φ R q (abs xᵣ) = ≡.cong abs (extensionality' (λ W w → inverseproof (map-⊎ φ id) (R ⟦⊎⟧ _≡_) (λ x → yak1 φ R q x) (xᵣ _≡_ ≡.refl)))
    inverseproof φ R q (app t t₁) = ≡.cong₂ app (inverseproof φ R q t) (inverseproof φ R q t₁)

    inverseproof' : ∀ {V W} (φ : V → W) {t1 t2} → ⟦Term⟧ (RelOf φ) t1 t2 → map φ t1 ≡ t2
    inverseproof' φ t = inverseproof φ (λ z → _≡_ (φ z)) (λ {i} {j} z → z) t 

    module TermOp (f  : IdTerm)
                  (fr : ⟦IdTerm⟧ f f)
                  {V W}
                  (φ  : V → W)
                  (t  : Term V) where
      lem : map φ (f t) ≡ f (map φ t)
      lem =  inverseproof' _ (fr _ (proof' φ t))  

module Lib {World : ★}
           (⟦World⟧ : ⟦★⟧ World World)
           {Name : World → ★}
           (⟦Name⟧ : (⟦World⟧ ⟦→⟧ ⟦★⟧) Name Name)
           {_∪_ : World → World → World}
           (_⟦∪⟧_ : (⟦World⟧ ⟦→⟧ ⟦World⟧ ⟦→⟧ ⟦World⟧) _∪_ _∪_)
           (map-∪ : ∀ {V W X} → (Name V → Name W) → Name (V ∪ X) → Name (W ∪ X)) where
    -- {-
    -- Worlds are types, binders are quantification over any value of any type.
    data Term (V : World) : ★ where
      var : Name V → Term V
      abs : (∀ {W} → Name W → Term (V ∪ W)) → Term V
      app : Term V → Term V → Term V

    -- Term is a functor (unlike PHOAS)
    map : ∀{U V} → (Name U → Name V) → Term U → Term V
    map f (abs t)   = abs (λ x → map (map-∪ f) (t x))
    map f (var x)   = var (f x)
    map f (app t u) = app (map f t) (map f u)
    -- -}

    {-
    data ⟦Term⟧ {a₁ a₂ aᵣ} {V₁ : Set a₁} {V₂ : Set a₂} (Vᵣ : ⟦Set⟧ aᵣ V₁ V₂) : Term V₁ → Term V₂ → Set (suc aᵣ) where
      var : (Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) var var
      abs : ((∀⟨ Wᵣ ∶ ⟦Set⟧ aᵣ ⟩⟦→⟧ Wᵣ ⟦→⟧ ⟦Term⟧ (Vᵣ ⟦⊎⟧ Wᵣ)) ⟦→⟧ ⟦Term⟧ Vᵣ) abs abs
      app : (⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) app app
    -}
    data ⟦Term⟧ {V₁ V₂} (Vᵣ : ⟦World⟧ V₁ V₂) : Term V₁ → Term V₂ → ★ where
      var : (⟦Name⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) var var
      abs : ((∀⟨ Wᵣ ∶ ⟦World⟧ ⟩⟦→⟧ ⟦Name⟧ Wᵣ ⟦→⟧ ⟦Term⟧ (Vᵣ ⟦∪⟧ Wᵣ)) ⟦→⟧ ⟦Term⟧ Vᵣ) abs abs
      app : (⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ) app app

    IdTerm = ∀ {V} → Term V → Term V
    ⟦IdTerm⟧ : ⟦★⟧ IdTerm IdTerm
    ⟦IdTerm⟧ = ∀⟨ Vᵣ ∶ ⟦World⟧ ⟩⟦→⟧ ⟦Term⟧ Vᵣ ⟦→⟧ ⟦Term⟧ Vᵣ

module LibProofs where
    World : ★
    World = ★
    Name : World → ★
    Name α = {!!}
    ⟦World⟧ : ⟦★⟧ World World
    ⟦World⟧ α β = {!!}
    ⟦Name⟧ : (⟦World⟧ ⟦→⟧ ⟦★⟧) Name Name
    ⟦Name⟧ αᵣ βᵣ = {!!}
    _∪_ : World → World → World
    α ∪ β = {!!}
    _⟦∪⟧_ : (⟦World⟧ ⟦→⟧ ⟦World⟧ ⟦→⟧ ⟦World⟧) _∪_ _∪_
    αᵣ ⟦∪⟧ βᵣ = {!!}
    map-∪ : ∀ {V W X} → (Name V → Name W) → Name (V ∪ X) → Name (W ∪ X)
    map-∪ = {!!}

  {-
    open Lib ⟦World⟧ ⟦Name⟧ _⟦∪⟧_ map-∪
    _∪_ = _⊎_
    _⟦∪⟧_ : (⟦★⟧ ⟦→⟧ ⟦★⟧ ⟦→⟧ ⟦★⟧) _∪_ _∪_
    _⟦∪⟧_ = {!!}

    data RelOf {A B : ★} (f : A → B) : A → B → ★ where
      relOf : ∀ {x} → RelOf f x (f x)

    module ⟦Term⟧-map
                (ext : ∀ {V W X} → (V → W) → (V ∪ X → W ∪ X)) where
                -- (⟦ext⟧ : ∀ {W₁ W₂} (Wᵣ : ⟦★⟧ W₁ W₂) (φ : ?) → RelOf φ ⟦∪⟧ Wᵣ → RelOf (ext φ)) where
        proof : ∀ {V W} (φ : V → W) t → ⟦Term⟧ (RelOf φ) t (map φ t)
        proof _ (var _)   = var relOf
        proof φ (abs f)   = abs (λ Wᵣ wᵣ → {!proof (ext φ)!})
        proof φ (app t u) = app (proof φ t) (proof φ u)

    module TermOp (f  : IdTerm)
                  (fᵣ : ⟦IdTerm⟧ f f)
                  {V W}
                  (φ  : V → W)
                  (t  : Term V) where
      lem : ⟦Term⟧ {!!} (map φ (f t)) (f (map φ t))
      lem = {!!}
      -- lem : map φ (f t) ≡ f (map φ t)
-- -}
-- -}
-- -}
-- -}
-- -}
