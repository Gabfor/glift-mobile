"use client";

import { Inter } from "next/font/google";
import { useMemo, useState } from "react";

const inter = Inter({ subsets: ["latin"], weight: ["400", "600", "700"] });

export default function ConnexionPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const isValid = useMemo(
    () => email.trim().length > 0 && password.trim().length > 0,
    [email, password]
  );

  return (
    <main
      className={`min-h-screen flex flex-col justify-between items-center bg-[#F8F8FC] ${inter.className}`}
    >
      <div className="w-full relative flex flex-col items-start">
        <div className="bg-gradient-to-b from-[#6C63FF] to-[#857DFF] h-60 w-full rounded-b-[3rem] px-6 pt-8">
          <p className="text-sm text-white/80">Bonjour,</p>
          <p className="text-2xl font-semibold text-white mt-1">Bienvenue sur Glift</p>
        </div>

        <div className="w-full flex justify-center">
          <div className="relative -mt-10 w-11/12 max-w-sm bg-white shadow-lg rounded-3xl p-6">
            <h1 className="text-lg font-semibold text-[#2E2E48] mb-5">Connexion</h1>

            <label className="block text-sm font-medium text-[#606077] mb-2" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="john.doe@email.com"
              className="border border-gray-200 rounded-md px-4 py-3 w-full text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#6C63FF]"
            />

            <label
              className="block text-sm font-medium text-[#606077] mt-5 mb-2"
              htmlFor="password"
            >
              Mot de passe
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="border border-gray-200 rounded-md px-4 py-3 w-full text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#6C63FF]"
              />
              <button
                type="button"
                aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
                onClick={() => setShowPassword((prev) => !prev)}
                className="absolute inset-y-0 right-3 flex items-center text-gray-400 hover:opacity-95 transition-opacity"
              >
                {showPassword ? (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth={1.8}
                    stroke="currentColor"
                    className="w-5 h-5"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 15.338 6.244 18 12 18c3.112 0 5.358-.73 7.022-1.9M6.228 6.228A9.956 9.956 0 0112 6c5.756 0 8.774 2.662 10.066 6a10.518 10.518 0 01-1.225 2.092M6.228 6.228 3 3m3.228 3.228L3 3m0 0 18 18"
                    />
                  </svg>
                ) : (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth={1.8}
                    stroke="currentColor"
                    className="w-5 h-5"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"
                    />
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                  </svg>
                )}
              </button>
            </div>

            <button
              type="button"
              disabled={!isValid}
              className="w-full py-3 mt-6 rounded-full font-semibold transition-all bg-[#F1EEF9] text-gray-400 disabled:bg-[#F1EEF9] disabled:text-gray-400 enabled:bg-[#6C63FF] enabled:text-white"
            >
              Se connecter
            </button>

            <div className="mt-4 text-center">
              <a
                href="#"
                className="text-[#6C63FF] text-sm font-medium hover:opacity-95 transition-opacity"
              >
                Mot de passe oublié
              </a>
            </div>
          </div>
        </div>
      </div>

      <div className="text-center text-gray-500 text-sm mb-8">
        Pas encore inscrit ?{" "}
        <a href="#" className="text-[#6C63FF] font-semibold hover:opacity-95 transition-opacity">
          Créer un compte
        </a>
      </div>
    </main>
  );
}
