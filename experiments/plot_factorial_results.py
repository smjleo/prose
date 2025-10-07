#!/usr/bin/env python3

import sys
import pandas as pd
import matplotlib.pyplot as plt
import argparse

def plot_probabilities(df, save_pdf=False):
    plt.figure(figsize=(5, 2.5))

    sess_data = df.dropna(subset=['sess_p'])
    sess_upper_data = df.dropna(subset=['sess_upper_p'])
    ctx_data = df.dropna(subset=['ctx_p'])

    if not sess_data.empty:
        plt.plot(sess_data['n'], sess_data['sess_p'], 'o-', label='Session', linewidth=2, markersize=6)
    if not sess_upper_data.empty:
        plt.plot(sess_upper_data['n'], sess_upper_data['sess_upper_p'], '^-', label='Session (upper)', linewidth=2, markersize=6)
    if not ctx_data.empty:
        plt.plot(ctx_data['n'], ctx_data['ctx_p'], 's-', label='Typing context', linewidth=2, markersize=6)

    plt.xlabel('n')
    plt.ylabel('Termination probability')
    plt.grid(True, alpha=0.3)
    plt.legend()

    n_max = df['n'].max()
    plt.xticks(range(0, n_max + 1, 5))

    plt.tight_layout()

    if save_pdf:
        plt.savefig('factorial_probabilities.pdf', bbox_inches='tight')
        print("Probability plot saved to factorial_probabilities.pdf")

def plot_times(df, save_pdf=False):
    plt.figure(figsize=(5, 2.5))

    sess_data = df.dropna(subset=['sess_time'])
    sess_upper_data = df.dropna(subset=['sess_upper_time'])
    ctx_data = df.dropna(subset=['ctx_time'])

    if not sess_data.empty:
        plt.plot(sess_data['n'], sess_data['sess_time'], 'o-', label='Session', linewidth=2, markersize=6)
    if not sess_upper_data.empty:
        plt.plot(sess_upper_data['n'], sess_upper_data['sess_upper_time'], '^-', label='Session (upper)', linewidth=2, markersize=6)
    if not ctx_data.empty:
        plt.plot(ctx_data['n'], ctx_data['ctx_time'], 's-', label='Typing context', linewidth=2, markersize=6)

    plt.xlabel('n')
    plt.grid(True, alpha=0.3)
    plt.legend()

    n_max = df['n'].max()
    plt.xticks(range(0, n_max + 1, 5))

    plt.yscale('log')
    plt.ylabel('Verification time (log seconds)',fontsize=9)

    plt.tight_layout()

    if save_pdf:
        plt.savefig('factorial_times.pdf', bbox_inches='tight')
        print("Time plot saved to factorial_times.pdf")

def main():
    parser = argparse.ArgumentParser(description='Plot factorial termination results')
    parser.add_argument('csv_file', help='Path to the CSV file containing results')
    parser.add_argument('--save-pdf', action='store_true',
                       help='Save plots as PDF files instead of just displaying')

    args = parser.parse_args()

    try:
        df = pd.read_csv(args.csv_file)

        required_cols = ['n', 'sess_p', 'sess_time', 'sess_upper_p', 'sess_upper_time', 'ctx_p', 'ctx_time']
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            print(f"Error: Missing columns in CSV: {missing_cols}")
            return 1

        df = df.replace('DNF', pd.NA)

        numeric_cols = ['sess_p', 'sess_time', 'sess_upper_p', 'sess_upper_time', 'ctx_p', 'ctx_time']
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors='coerce')

        df = df.sort_values('n')

        print(f"Loaded {len(df)} rows of data")
        print(f"n ranges from {df['n'].min()} to {df['n'].max()}")

        sess_success = df['sess_p'].notna().sum()
        sess_upper_success = df['sess_upper_p'].notna().sum()
        ctx_success = df['ctx_p'].notna().sum()
        print(f"Session verifications: {sess_success}/{len(df)} successful")
        print(f"Session (upper) verifications: {sess_upper_success}/{len(df)} successful")
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
