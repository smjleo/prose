#!/usr/bin/env python3

import sys
import pandas as pd
import matplotlib.pyplot as plt
import argparse

SESSION_COLOUR = '#2a78d6'
CTX_COLOUR = '#eb6834'

def plot_probabilities(df, save_pdf=False):
    plt.figure(figsize=(5, 2.5))

    sess_data = df.dropna(subset=['sess_p'])
    ctx_data = df.dropna(subset=['ctx_p'])

    if not sess_data.empty:
        plt.plot(sess_data['participants'], sess_data['sess_p'], 'o-', color=SESSION_COLOUR,
                 label='Session', linewidth=2, markersize=5)
    if not ctx_data.empty:
        plt.plot(ctx_data['participants'], ctx_data['ctx_p'], 's-', color=CTX_COLOUR,
                 label='Typing context (lower bound)', linewidth=2, markersize=5)

    plt.xlabel('#participants')
    plt.ylim(0, 1.05)
    plt.ylabel('Deadlock-freedom probability', fontsize=9)
    plt.grid(True, alpha=0.3)
    plt.legend()

    n_max = df['participants'].max()
    plt.xticks(range(5, n_max + 1, 5))

    plt.tight_layout()

    if save_pdf:
        plt.savefig('factorial_probabilities.pdf', bbox_inches='tight')
        print("Probability plot saved to factorial_probabilities.pdf")

def plot_times(df, save_pdf=False):
    plt.figure(figsize=(5, 2.5))

    sess_data = df.dropna(subset=['sess_time'])
    ctx_data = df.dropna(subset=['ctx_time'])

    if not sess_data.empty:
        plt.plot(sess_data['participants'], sess_data['sess_time'], 'o-', color=SESSION_COLOUR,
                 label='Session', linewidth=2, markersize=5)
    if not ctx_data.empty:
        plt.plot(ctx_data['participants'], ctx_data['ctx_time'], 's-', color=CTX_COLOUR,
                 label='Typing context', linewidth=2, markersize=5)

    plt.xlabel('#participants')
    plt.grid(True, alpha=0.3)
    plt.legend()

    n_max = df['participants'].max()
    plt.xticks(range(5, n_max + 1, 5))

    plt.yscale('log')
    plt.ylabel('Verification time (log seconds)',fontsize=9)

    plt.tight_layout()

    if save_pdf:
        plt.savefig('factorial_times.pdf', bbox_inches='tight')
        print("Time plot saved to factorial_times.pdf")

def main():
    parser = argparse.ArgumentParser(description='Plot factorial deadlock-freedom results')
    parser.add_argument('csv_file', help='Path to the CSV file containing results')
    parser.add_argument('--save-pdf', action='store_true',
                       help='Save plots as PDF files instead of just displaying')

    args = parser.parse_args()

    try:
        df = pd.read_csv(args.csv_file)

        required_cols = ['n', 'sess_p', 'sess_time', 'ctx_p', 'ctx_time']
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            print(f"Error: Missing columns in CSV: {missing_cols}")
            return 1

        df = df.replace('DNF', pd.NA)

        numeric_cols = ['sess_p', 'sess_time', 'ctx_p', 'ctx_time']
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors='coerce')

        df = df.sort_values('n')
        # w0, ..., wn and dummy: n + 2 participants computing (n - 1)!.
        df['participants'] = df['n'] + 2

        print(f"Loaded {len(df)} rows of data")
        print(f"n ranges from {df['n'].min()} to {df['n'].max()}")

        sess_success = df['sess_p'].notna().sum()
        ctx_success = df['ctx_p'].notna().sum()
        print(f"Session verifications: {sess_success}/{len(df)} successful")
        print(f"Context verifications: {ctx_success}/{len(df)} successful")

        plot_probabilities(df, args.save_pdf)
        plot_times(df, args.save_pdf)

        if not args.save_pdf:
            print("Displaying plots... (close the plot windows to exit)")
            plt.show()

        return 0

    except FileNotFoundError:
        print(f"Error: Could not find file {args.csv_file}")
        return 1
    except Exception as e:
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
