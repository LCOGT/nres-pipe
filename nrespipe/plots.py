import matplotlib
matplotlib.use("Agg")
from matplotlib import pyplot
import numpy as np

pyplot.rcParams["figure.figsize"] = (10, 6)
pyplot.style.use('ggplot')

site_colors = {'elp': 'red', 'lsc': 'blue', 'cpt': 'green', 'tlv': 'brown'}
site_labels = {'elp': 'elp nres02', 'lsc': 'lsc nres01', 'cpt': 'cpt nres03', 'tlv': 'tlv nres04'}


def signal_to_noise_model(reference_flux=180000, read_noise=5):
    """
    calculate a s/n model V mag vs S/N
    :param reference_flux: Zeropoint of the flux
    :param read_noise: Read noise
    :return: mag, signal_noise(mag)
    """
    mag = np.arange(0, 14, 0.5)
    s = reference_flux * (10.0 ** (-0.4 * mag))
    # Currently we assume 5 pixels per resolution element to be consistent with Tim Brown's IDL code
    sn = s / np.sqrt(s + 5 * read_noise ** 2.0)
    return mag, sn


def plot_model(reference_flux=0.0, read_noise=0.0, color='black', label=None):
    mag, signal_to_noise = signal_to_noise_model(reference_flux, read_noise)
    pyplot.plot(mag, signal_to_noise, label=label, color=color)

def plot_signal_to_noise(output_filename, signal_to_noise_table, sites, daysobs):

    # Read Noise is assumed to be 7.75 in the IDL pipeline (hard coded)
    # Assumption: S/N= 10 for 20 min on V=12 start (NSF proposal)
    # hence S/N (Texp=60, V=12) = 10 * sqrt (6.3) / sqrt (20) = 5.6,
    # Trickier, worst case: S/N=100 to reach 3m/s for V=12 mag in 60 minutes
    # S/N (t=60 sec) = 100 /sqrt (60) = 12.9
    # Apparently this is a long running figure so make sure you are starting with a fresh clear figure.
    pyplot.clf()
    models = [{'color': 'gray', 'label': 'lsc nres01 pre-fl10', 'reference_flux': 500000, 'read_noise': 1e-9},
              {'color': 'blue', 'label': 'lsc nres01', 'reference_flux': 180000, 'read_noise': 1e-9},
              {'color': 'red', 'label': 'elp nres02', 'reference_flux': 900000, 'read_noise': 1e-9},
              {'color': 'green', 'label': 'NSF promise revised', 'reference_flux': 1978682, 'read_noise': 1e-9},
              {'color': 'cyan', 'label': 'TESS classification', 'reference_flux': 995267, 'read_noise': 1e-9}]
    for model in models:
        plot_model(**model)

    for site, dayobs in zip(sites, daysobs):
        site_table = signal_to_noise_table[np.logical_and(signal_to_noise_table['site'] == site,
                                                          signal_to_noise_table['dayobs'] == dayobs)]
        pyplot.plot(site_table['Vmag'], site_table['sn'] * np.sqrt(60.0 / site_table['exptime']),
                    'o', color=site_colors[site], label=site_labels[site] + ' {dayobs}'.format(dayobs=dayobs))

    # prettyfication
    pyplot.yscale('log')
    legend = pyplot.legend(bbox_to_anchor=(1, 1), loc='upper left', ncol=1, fontsize=15)
    pyplot.xlim([0, 14.9])
    pyplot.ylim([0.5, 2e3])
    pyplot.xlabel("\nV mag", fontsize=20)
    pyplot.ylabel("S/N\n", fontsize=20)
    pyplot.title("NRES S/N model\n per resolution element for 60 sec exposure, 5100 Ang\n", fontsize=20)
    pyplot.grid(b=True, which='major', color='k', linestyle='-')
    pyplot.grid(b=True, which='minor', color='k', linestyle='--')
    pyplot.tick_params(axis='both', which='major', labelsize=15)
    pyplot.tick_params(axis='both', which='minor', labelsize=10)
    pyplot.subplots_adjust(top=0.88)
    pyplot.savefig(output_filename, box_extra_artists=(legend,), bbox_inches="tight", dpi=400)


def plot_signal_to_noise_Bp(output_filename, signal_to_noise_table, sites, daysobs):

    # Read Noise is assumed to be 7.75 in the IDL pipeline (hard coded)
    # Assumption: S/N= 10 for 20 min on V=12 start (NSF proposal)
    # hence S/N (Texp=60, V=12) = 10 * sqrt (6.3) / sqrt (20) = 5.6,
    # Trickier, worst case: S/N=100 to reach 3m/s for V=12 mag in 60 minutes
    # S/N (t=60 sec) = 100 /sqrt (60) = 12.9
    # Apparently this is a long running figure so make sure you are starting with a fresh clear figure.
    pyplot.clf()
    models = [{'color': 'gray', 'label': 'lsc nres01 pre-fl10', 'reference_flux': 500000, 'read_noise': 1e-9},
              {'color': 'blue', 'label': 'lsc nres01', 'reference_flux': 180000, 'read_noise': 1e-9},
              {'color': 'red', 'label': 'elp nres02', 'reference_flux': 900000, 'read_noise': 1e-9},
              {'color': 'green', 'label': 'NSF promise revised', 'reference_flux': 1978682, 'read_noise': 1e-9},
              {'color': 'cyan', 'label': 'TESS classification', 'reference_flux': 995267, 'read_noise': 1e-9}]
    for model in models:
        plot_model(**model)

    for site, dayobs in zip(sites, daysobs):
        site_table = signal_to_noise_table[np.logical_and(signal_to_noise_table['site'] == site,
                                                          signal_to_noise_table['dayobs'] == dayobs)]
        pyplot.plot(site_table['Bpmag'], site_table['sn'] * np.sqrt(60.0 / site_table['exptime']),
                    'o', color=site_colors[site], label=site_labels[site] + ' {dayobs}'.format(dayobs=dayobs))

    # prettyfication
    pyplot.yscale('log')
    legend = pyplot.legend(bbox_to_anchor=(1, 1), loc='upper left', ncol=1, fontsize=15)
    pyplot.xlim([0, 14.9])
    pyplot.ylim([0.5, 2e3])
    pyplot.xlabel("\nBp mag", fontsize=20)
    pyplot.ylabel("S/N\n", fontsize=20)
    pyplot.title("NRES S/N model\n per resolution element for 60 sec exposure, 5100 Ang\n", fontsize=20)
    pyplot.grid(b=True, which='major', color='k', linestyle='-')
    pyplot.grid(b=True, which='minor', color='k', linestyle='--')
    pyplot.tick_params(axis='both', which='major', labelsize=15)
    pyplot.tick_params(axis='both', which='minor', labelsize=10)
    pyplot.subplots_adjust(top=0.88)
    pyplot.savefig(output_filename, box_extra_artists=(legend,), bbox_inches="tight", dpi=400)
