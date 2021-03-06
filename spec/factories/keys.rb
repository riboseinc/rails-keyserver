# frozen_string_literal: true

FactoryBot.define do
  factory :rails_keyserver_key, class: "Rails::Keyserver::Key" do
    # TODO: metadata needs to go away?
    metadata do
      {
        "subkeys" => [
          2.times.map do
            {
              "fpr" => SecureRandom.hex(32),
            }
          end,
        ],
      }.to_s
    end
    activation_date "2016-12-05 14:29:40"
    owner           { FactoryBot.create :generic_key_owner }

    private "hi"

    factory :rails_keyserver_key_pgp, class: "Rails::Keyserver::Key::PGP" do
      # TODO: convert this factory to emit RNP-compatible format, i.e. include
      # 'grip', 'primary_key_grip'(only for subkeys) and 'fingerprint'

      public <<~EOKEY
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        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
        =Q6Cx
        -----END PGP PUBLIC KEY BLOCK-----
      EOKEY

      private <<~EOKEY
        -----BEGIN PGP PRIVATE KEY BLOCK-----
        Version: GnuPG v2.0.22 (GNU/Linux)

        lQcYBFt9GtABEADVNxv3RCgAL776aaB0ahVCUBM1jazgjgL7+86f1fRdU4CP4sul
        D6yWPRTKFY2GKUooXla743iiUGj8ehxaWjl9FfZsmTnpEF83ql0gKaVn3TtKeaLC
        abPn7wB9ripC7E5PtGDUnRRYNSPzPBKVhHASS0+78kLJ7StUP60qs12ZJwlc8l85
        VI3HSiO2SZPoS/CEYFJfrnwvv4ftPAcAyWujCV3k0/k/P/pPs2+AyJVwutdZUtCh
        3QrsRfueqT47lAlVDNH4dNAz/S+esnwhnre9LSIenjp3Bed886wx6+Sx/D2VLwGm
        FxDqRfpF8lZ1Mjg4md3imaPmTyi85hNPfJMvPgh7VdlZK1QEp84+iUBB7z2qmBjJ
        0XpKI6+IZg4LOU1UY13QFyz2AZPdMt9Y17nsfQ5svpiyK7h3GbuPU5H9iZs8K+TQ
        XJGmIcHaQoEYFRycuOrVmytL8Lu24w2Z7EN7EofvrBqQv6toARALtghgS7xwVZdI
        zKP5HEB0kmNcjpnf9Ke0rwo5JfQu5zxLpwszGqJj9d9Pn+zECp6MkJvFcMj3eadD
        j+jSgh2XQ/LI9gJ/1gwQdNCDNFjkGcPJTQrLuaCx1YkBUXQqTBEEzI+5HeP9T18V
        ftoJQ3u1gDElo/6E5ifnzoBOPrEDJOQj1wC8T7zsDTUcEqJpCTHMGAe7/QARAQAB
        AA/9HP6mzLAl0WqsybByC8q+U9uAVTzMOOhPAxXp8iX+Gm/n0IlawLpaMb8iM94M
        9iToywcTO+9R4R7WvBjeALJ61WYWcgu/SpC5piAClIRdVDvLW5QhfFc0CjMgCbdU
        029/scqZjWhEEz+8wQ/XBiKxu+cmc2xdRUj9prIXGjK0pIZguVVTekAjnKmaJCiq
        1sD29wWDRjQ7+qFM+oe6exKpEs2MCXmDEGUipNKFtAly+xbJgMHokc51tQ5KSrgA
        uMjnoPuClUtLYfqJDod+pnLHUVBRLsE9OaDhq0YW0V4fJk4jUMWI75185SL5hygO
        tlbLOvU/rZhPp9r1cwTFtP4/pIH8PQrPiVB6Kg1TkxbZXDMOfz+Pz76tHWaVneQy
        0qXq8Z7KTXsiqk44CUsFYuuU4kPCfavl6DlXPlOU9RnO4HzlXjv/Gvat6WVWOOBi
        1OJ4HaKCnDMkJbyi1V5WHs/XXz44NEzrZVF72D9zZMtjMH/fMtKVznNi/TesGmSl
        qE0u4hzG1uQ9gZP14nxU5M57gl1cbzh/MnXml6XMayszew629vmbeHLe8Tn1ab+O
        6bSW5FA3X7lg7KR0nU1aEuAIxEyXTUxafgijcihJ4cCASsemRSxRM6HQpHZoBNAN
        ZDIf8rLR9dnpasR8fC7+S1kZUTKDQJouTv7KIgiQTeOmz4EIANXcIkWScaPBNiQu
        3LnkokbxTNNCij2Q3UqJ2ZWrbfdkLlkrfOV9FsKpRsNkuqXDfQ/6bijhH30iiatZ
        2jpYFpP887pZd+hm5ihnW/IHcxicN1KtoIRDWtnYnJgzrVfKgL5G8e9kZsZhoNeQ
        75v6VHYrTlEPP6cdm3sHPTSGhFWg5R+WTTQSnle3qRCXGd9Az7QSIS7ccGt//m67
        gYA5/SCPoK3ZF5Kr2ZrbFkavOO3ICUlrZ1onAsItpjEGsr3rryvjnNra7cnTA0aJ
        9tDF1k9rbNilJx6W5ZcRr9ExddZR+Q8bhFSP9IhDrOM0H+TO92G4HVuqO28lZ0xy
        o6ZOQIEIAP86dUFZvKaTM2jEyn3RUik8qrECErmNWLiStvDwM6jFQ27BkPmgfeUB
        icYDekEp3R0aCv87+3Y8fSjGJtq1OsM1/rJ+urvS6H9HMuNLZb2dzMDzhAvCFETO
        88vyW3UqLUp7W9l1jGxeRgBD/q/eNXRM0DAS9B8zNI5oK/o1brb+/TY64n95A4sW
        NonKBcGpxqeb13bv1CoiACjob+tjP0cJ5voJ/S/rI/qF0iw7JV0Vv6+dp0QFaZIC
        hHb1DSJjVHD31XyFUcd8EzARQu0aGSesaPNhQLxjY5WJHgwPcTKodxuLavSe53Tb
        LLFefEauzGywKP+EiebziU+y4wSzvX0IAMCTVNXqsrVVdRV3eRyzGRgdF8qTvDSA
        0O7+WLEpvjlryy072X57DYQ36Spf+ACr4DR6S6lzKpbepEtn3LnKb6QI5/IxRYpW
        zkd0bOOGD4rI2D4e1dWcdw6NVyLmktzXh7ml8De/Qc78rWb0qcxyXENHNe4BGIdL
        B8CTmz0oTj8BwkH04aA2DS/9FG+5MXa+nKJzgVlyKdFaorDzJcq+KAWI/r0aTrYl
        KqPFBUN46g5KaD1WR1PWjkj3mXIuJEmLSGpR3KuWacoeKkXrHRD/pLDoTlij8SK1
        okS5gfJtRAY7ShZPGLCE4D3ctwin+VUcmBxyYPSfk/vFAR2YKeo1l+N+drRFU3Bl
        Yy1vbmx5IEtleXMgKFRoaXMgaXMgb25seSBmb3Igc3BlY3MuKSA8c3BlYy5vbmx5
        LmtleXNAZXhhbXBsZS5jb20+iQI5BBMBAgAjBQJbfRrQAhsDBwsJCAcDAgEGFQgC
        CQoLBBYCAwECHgECF4AACgkQoEuv3WCehd1x2Q/7BLTQWJxkUJ7W0jzY2Hr1JCWA
        V9YXzZ1f1vJLwOptB+xLSHGY1goFNLF10QI/uP6hZUVukYovwDy/7r7H5oMtAbsa
        7wyzOAFIEj4Mw58BfWOINjdDT26svblTuqjGgv31gCJCZatuUA/VFLXUp1w6HrWp
        tMhof4XanXQn7e5gLcbnXCgpmoZ9CVGxXk2lCxiGevH5eaRPn05i11h7SrOVwiwW
        587HAJxRNtF2UqCQmTPHYCLoFDoEMnUlPHWNAw02pvw42zY3spxLVslSwrVCHzSF
        iuSKxFWPrtxrXSLjwnTu3Z7O03J6VCMQgxFahIhoRxRUK7aywFF5fbNs24BWths7
        3NF3kSxjrEG5WB4vQeLjB95KcBBVcRCQwHOqV/rbOHXe6aDLUYkS+E2fxyQFRtnr
        1ZGimTC555DPkBOga/VKS30Go3QQsxNaDOjcU2lcPCesGMN8lq7ye1UDT0R506KZ
        lHp3bpmyR6dCiUdWNNgijDu1TK1JHBzrPwFU4Ukstco9ONSQri60H2vy7eRweXXT
        RfNflChJmTsRI/cQHgNTh0X32iWnvKROttVy4Ae4s6ZhrIfLpnSvlA764O0ZJbdF
        i56+pFTJMXT9jm+cV0fmrAOfqwOpp051uQOeRL7kuIkKLrsh2bdNvKwqDQZn/dCK
        Sig8fRtaGPIL7BtNFe6dBxgEW30a0AEQALmqHnISpzfT9nkRfjW00I1CEWv8G9Bk
        NjKx7n8Fncvgll8SpZKO45UtR1H/6xPqgnSy6pzgf2eE6NwyF9Ay6TdVueYVygNb
        76m9XVRmVvYTuZiY66whpehPWXfT3/rA2W3EnywAW1lwrlJDf8e6uej4tEDGPQMA
        e4diCh15krJuA+DVCtW6L91lRZMaiYUCM9vnttuLTqmm4DiftMdmqWOF5hxAsLBP
        /0FhFwjMNC8dH8g7ipCZiiu2l224fn232UnPxKhky3SPbIFNF7JtKwauGj+n7wkC
        FyqCopHU8B4n3O9WkwiodMZ1X4ZGJ8YxG4Nc/UOaojUyalHQ5HMkIRMtna6DMOzu
        NWz3xvYJ9l62IHfb82itPxTVfM+axKNxstO40/cSIPbTCVkw+GGYPLYhNGa+O3s+
        oG5ELP84mq44Ul/2b22N2ER8JGfTDLqxurNJ/5hBOvvtL9BX0LSXAjz40KynHmvZ
        slziNLqW/DnNn0iscJfivP+O4XVXc73MyCTMiPfUaL9xDlWWaKY36tKzzvRlXPxt
        DjdHqvU3uxBHaeZyxUCEg3IemtFfYaa5fEvVFk01QO1THMT2wQzby8UgXj4Y6Dnk
        ZJxbFFSlDd4ARmXirTVGcBNz8w53ssHSZ+3LZjtFo13ck1v5/3hQcwzSe0ZSn8ug
        +Lehe20pDhlPABEBAAEAD/sEVE7F0mqHQQGO5CjNcUJG7ApHa8JtMxEDsxI7l/Kq
        DmuAwroNHrZk/yfLPr3h5tBtP/oF2jk1s6H4u98Q0gwED2vML7v16gPInZfVuxrg
        2zuVkWJeYquNwMw7PllaCwU/iUgVDIuyTZATqf8KmG+RH6ghmDtT5qFnFTBu9lz1
        2EDQXA2M+NVHbzoRrQcpM/MPi8dTmQMJJGTBGFa7jUjJf1qyVAjqtW1LqqPL+q61
        SrD86rlItV2xe6M6ZHr71sx0RAyBtS5yutu/Ic8cTdBf/ezGYcIPbpk9TnzADKOV
        g4HpBIL6+eVkbLDF46kiT1GHkzhoyzEFzOvOwPpEmYdXt+Cin5NvnLK+0FVPpSKC
        EbjniLG2NFHM0P+NFm0UoOYA2UaoNpTHDkJkTW/snwNt5BgPejt+Ix2jQrT6Te9Y
        CVMA10W6KWO+wVH2xaM9X01OJAD22Wt2NvJ6ZeXRUNB9yk7TIRh1/r6RpU0HezaK
        2oTvbQvMBoEL5WARnvGop19+v5rlLtch1prCcj3Aiprbr8innoP+xd1840PlQltR
        zNekw7cuX1tmlxQGousE5sEE9/cEH/6WqZxiaieXypWyApqpG61MUiZbDbtotSya
        QxS3TN5MwqO5a8vI553DkmDFLe1XQgIY9/x7WK7h3sOVYV+Cr67gC6fNdhT+OT3+
        uQgAw+jKgFxkV1uxEFYq3Ua67SRVchvVO4NQPc7MM/WF8UjYNdoq0d6b/iwqcSdh
        zxI9e1TPjRs9fFx8gYgAOZEesIyoN6X57MD1wEKDFXEWVcQ6xgaFQrZusu9hsWNF
        7Dqiv+wzPr7NMPqrHolC2AMTDaCppRwG08zE2hJrH270991Q32+QNRItGQvAjktf
        tJzOpDHy8auDnZZWqcscVvmqCS/2SaQywKxiXRDUQkZ4OgMCWl0INqe2LLM5MXYE
        kuXEiukhrVu0juPDFkvcXtl4FArlLnbtUflUGn90jOEy6lo8cWu7+T3+ahw3nWGT
        sDrcXSoHGfqQDdsdi4VS4BltaQgA8pziRlSBWcGLgQBrGVtwy5KtbjovEDy1WZQV
        yzOap3MNLTmNn6zcTdInm1so4HmGDvKZL24TRlpAXygimHjXtyXGT9OxuGRFUpe9
        BzyX1wUu7gHcfi92TkHUnLbE/oG14itvZvXUaS9q3IyVkZj9v83yb72Wq9vSXKyf
        PKs115DyZc+IVS8xvIEtwbD3W9a9OoL6smc4L0b2/vfZiBLYTWIcmIz6jU/vTLbc
        S8Qid9vIW5MHMQFJ7iM8UL6IRWbxc1hpF+VOSy2E+RcnzM4bU742bX8DkpPsk2+1
        T2eBzanjLkxHkobNk4hiwqyh1sLHq4cdCniTm1YqMk/QwbMh9wf/bvdrJ0dxjHG3
        UXxS++jk6H6e6TdH5CvAAXh4gpTl5jKK9hkknNTgYZSmQrsSGgKQk6kQy53OLcw4
        ZRy6wuwBlAalVj60xK2E+1zG1lpzemnxmJRmd6wYUSJ/5Kr1E34l4h3mYxi1Qhel
        Od3VDeLSwZrbNK2aZ8PUKQjBhkSfXibmx7IpVV7QO10X96lW3X5iX4IVPzZXRrKN
        G6muO7V5ZDLq8xG8VCzc4V7jsCJWm43EgoN2+tUJwkeZW1ArlejlzyqRLjovLsvl
        R7/c9ZGVR8TLypPe3Xo7on31poBHtxBSxS5dwqIEqRO7ASQNfvAInMWy4Mae4aog
        YFlpCiYjT4YuiQIfBBgBAgAJBQJbfRrQAhsMAAoJEKBLr91gnoXdkZgQANL4ieu6
        Zs25Q0qxmSwNBJr/5w83+4ZVC+4NfrXo+iOjzpixwgux/+a+2TmrHBcXuQ8PxXfl
        OIDONOvpqzYWaUSyy/dvEqXOQZU0qrNB0Kb1UwsRAOakeiTvw7r1waRktCPulxz4
        fUydnpQ6YX0oAhT3iFov9lAkKqdjf6Pd/ygzbmyioahPMOWtEgt7tjL/QqxSmWvC
        I6t9y0F0Vk2FWSnJPjr96PHsWc6fc+1CQF8YNidYWfhjXO6C2DP379rpIcL/lm9Z
        KKKaPmeqEXUvbkyKT7DuPufA/xK38BiLgKBSrqzZtSOoix9Sx/x5wveE63QPG4p2
        Mpz6sg6jbMl+ULKwi1X9p2lWAUU18yerbErYe6X6oms4li8Q8cc5XD9BwQSd1NMp
        38+0G2jJ4aJqwQgPsHV/bnsibwZZ5muvSzCdEcp4Ig72W7MH/mGYksyXzvoYSLQw
        gkKZJI0oJcblLbvNskdN57x7rCNyaLoRLK5UopRbnXcKMwR34jiqhnNV0D27ZcIs
        ctQ5rGwX0hvn2WZKaZRuUAh2tzpOoKJL9HfrNZvpteImOHKOzQDcMZbGBxh+t4oB
        v6s+oeeVIAA2hgbPPT1hmBOQZNeIRg16tHUsUuXIfvn5l0BdKKJdjb4wFM0v+FQc
        eo/QCLum+VKj+rxGskc/f4HlVwKWtgskgh+T
        =7sLI
        -----END PGP PRIVATE KEY BLOCK-----
      EOKEY
    end
  end
end
